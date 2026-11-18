# ============================================================================
# onprem-node — one GCE VM shaped like a partner site: a single-node
# kubeadm cluster, with PostgreSQL (Rucio), MySQL (FTS) and Vault running
# on the same machine but OUTSIDE Kubernetes, the way a partner's cluster
# reaches existing database and secret-store servers.
#
# Everything is installed by the startup script (templates/), which runs on
# every boot and is idempotent. Secrets reach the VM only through Secret
# Manager (read with the VM's own service account), never through instance
# metadata: on a plain VM every pod can read the metadata server.
# ============================================================================

terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

locals {
  certs = {
    "vaultcert.pem" = file("${var.certs_dir}/vaultcert.pem")
    "vaultkey.pem"  = file("${var.certs_dir}/vaultkey.pem")
    "rucio_ca.pem"  = file("${var.certs_dir}/rucio_ca.pem")
  }
}

# --- Addresses -----------------------------------------------------------
# The internal IP is fixed so the Vault certificate (VAULT_SAN) and the
# GitOps values (Vault server, DB hosts) can be written before the VM exists.

resource "google_compute_address" "external" {
  name         = "${var.name_prefix}-node-ip"
  project      = var.project_id
  region       = var.region
  address_type = "EXTERNAL"
}

resource "google_compute_address" "internal" {
  name         = "${var.name_prefix}-node-internal-ip"
  project      = var.project_id
  region       = var.region
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  address      = var.internal_ip
}

# --- Database passwords ------------------------------------------------------
# Alphanumeric only: they are written into SQL statements, DSNs and config
# files without further escaping.

resource "random_password" "rucio_db" {
  length  = 32
  special = false
}

resource "random_password" "fts_db" {
  length  = 32
  special = false
}

# --- Service account -----------------------------------------------------------

resource "google_service_account" "node" {
  project      = var.project_id
  account_id   = "${var.name_prefix}-node"
  display_name = "${var.name_prefix} single-node cluster VM"
}

resource "google_project_iam_member" "logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

resource "google_project_iam_member" "monitoring" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.node.email}"
}

# The CI identity needs serviceAccountUser on this SA to attach it to the VM
# (same pattern as the testbed's validation-storage module).
resource "google_service_account_iam_member" "ci_can_use_node_sa" {
  count              = var.terraform_ci_sa_email == null ? 0 : 1
  service_account_id = google_service_account.node.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${var.terraform_ci_sa_email}"
}

# --- Secrets the VM reads at boot ------------------------------------------------

resource "google_secret_manager_secret" "node" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-node"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "node" {
  secret = google_secret_manager_secret.node.id
  secret_data = jsonencode(merge(local.certs, {
    rucio_db_password = random_password.rucio_db.result
    fts_db_password   = random_password.fts_db.result
  }))
}

# Filled by scripts/vault-init.sh (one version, never by Terraform): the
# unseal key and root token from `vault operator init`. The startup script
# unseals Vault with it after every reboot. A reference-only shortcut;
# partners run their own unseal procedure or auto-unseal.
resource "google_secret_manager_secret" "vault_init" {
  project   = var.project_id
  secret_id = "${var.name_prefix}-vault-init"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_iam_member" "node_reads" {
  for_each = {
    node       = google_secret_manager_secret.node.secret_id
    vault_init = google_secret_manager_secret.vault_init.secret_id
  }
  project   = var.project_id
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.node.email}"
}

# --- VM -----------------------------------------------------------------------

resource "google_compute_instance" "this" {
  name         = "${var.name_prefix}-node"
  project      = var.project_id
  zone         = var.zone
  machine_type = var.machine_type
  tags         = [var.node_tag]
  labels       = var.labels

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
      type  = "pd-balanced"
    }
  }

  network_interface {
    subnetwork = var.subnet_id
    network_ip = google_compute_address.internal.address
    access_config {
      nat_ip = google_compute_address.external.address
    }
  }

  service_account {
    email  = google_service_account.node.email
    scopes = ["cloud-platform"]
  }

  metadata = {
    startup-script = templatefile("${path.module}/templates/startup-script.sh.tftpl", {
      gateway_api_version  = var.gateway_api_version
      node_secret_id       = google_secret_manager_secret.node.id
      vault_init_secret_id = google_secret_manager_secret.vault_init.id
      kubernetes_minor     = var.kubernetes_minor
      pod_cidr             = var.pod_cidr
      subnet_cidr          = var.subnet_cidr
      flannel_version      = var.flannel_version
      local_path_version   = var.local_path_version
      valstorage_hostname  = var.valstorage_hostname
      valstorage_ip        = var.valstorage_ip
      kubeadm_config = templatefile("${path.module}/templates/kubeadm-config.yaml.tftpl", {
        node_name          = "${var.name_prefix}-node"
        internal_ip        = google_compute_address.internal.address
        external_ip        = google_compute_address.external.address
        kubernetes_version = var.kubernetes_version
        pod_cidr           = var.pod_cidr
        service_cidr       = var.service_cidr
      })
      vault_hcl = templatefile("${path.module}/templates/vault.hcl.tftpl", {
        internal_ip = google_compute_address.internal.address
      })
    })
  }

  allow_stopping_for_update = true

  depends_on = [
    google_secret_manager_secret_version.node,
    google_secret_manager_secret_iam_member.node_reads,
  ]
}
