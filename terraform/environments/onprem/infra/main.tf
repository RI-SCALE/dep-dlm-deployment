terraform {
  required_version = ">= 1.7"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  name_prefix = "dep-dlm-${var.environment}"
  zone        = "${var.region}-b" # same zone choice as the testbed (europe-west3-a had capacity issues)
  node_tag    = "${local.name_prefix}-node"
  dns_domain  = "${local.name_prefix}.example.com"

  # Same keys as the testbed's modules/secrets/certs.tf: the validation
  # storage's startup script reads exactly these (key => file in certs_dir).
  valstorage_certs = {
    "hostcert.pem"                   = "hostcert.pem"
    "hostkey.pem"                    = "hostkey.pem"
    "hostcert_with_key.pem"          = "hostcert_with_key.pem"
    "rucio_ca.pem"                   = "rucio_ca.pem"
    "tls_ca_bundle.pem"              = "tls_ca_bundle.pem"
    "5fca1cb1.0"                     = "rucio_ca.pem"
    "5fca1cb1.signing_policy"        = "5fca1cb1.signing_policy"
    "b96dc756.0"                     = "b96dc756.0"
    "b96dc756.signing_policy"        = "b96dc756.signing_policy"
    "storm-webdav-localhostcert.pem" = "storm-webdav-localhostcert.pem"
    "storm-webdav-localhostkey.pem"  = "storm-webdav-localhostkey.pem"
    "xrd3cert.pem"                   = "xrd3cert.pem"
    "xrd3key.pem"                    = "xrd3key.pem"
    "xrd4cert.pem"                   = "xrd4cert.pem"
    "xrd4key.pem"                    = "xrd4key.pem"
    "teapot1cert.pem"                = "teapot1cert.pem"
    "teapot1key.pem"                 = "teapot1key.pem"
    "teapot2cert.pem"                = "teapot2cert.pem"
    "teapot2key.pem"                 = "teapot2key.pem"
  }
}

module "networking" {
  source = "../../../modules/networking"

  project_id   = var.project_id
  region       = var.region
  name_prefix  = local.name_prefix
  subnet_cidr  = var.subnet_cidr
  node_tag     = local.node_tag
  public_ports = var.public_ports
}

module "node" {
  source = "../../../modules/onprem-node"

  project_id  = var.project_id
  region      = var.region
  zone        = local.zone
  name_prefix = local.name_prefix
  subnet_id   = module.networking.subnet_id
  subnet_cidr = module.networking.subnet_cidr
  node_tag    = local.node_tag
  internal_ip = var.node_internal_ip
  certs_dir   = var.certs_dir

  valstorage_hostname = module.validation_storage.hostname
  valstorage_ip       = module.validation_storage.external_ip

  terraform_ci_sa_email = "dep-dlm-terraform-ci@${var.project_id}.iam.gserviceaccount.com"

  labels = {
    environment = var.environment
    component   = "onprem-node"
  }
}

# --- Validation storage: the testbed's module, pinned by `make sync` ----------

# Private zone of this VPC; the module adds the validation storage's A record.
resource "google_dns_managed_zone" "internal" {
  name       = "${local.name_prefix}-internal"
  dns_name   = "${local.dns_domain}."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = module.networking.network_id
    }
  }
}

# The validation storage's certificates (the testbed keeps them in its
# dep-dlm-certs secret; here Vault holds the cluster's, so it gets its own).
resource "google_secret_manager_secret" "valstorage_certs" {
  secret_id = "${local.name_prefix}-valstorage-certs"
  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "valstorage_certs" {
  secret = google_secret_manager_secret.valstorage_certs.id
  secret_data = jsonencode({
    for key, file_name in local.valstorage_certs : key => file("${var.certs_dir}/${file_name}")
  })
}

module "validation_storage" {
  source = "git::https://github.com/RI-SCALE/dep-dlm-testbed.git//deploy/terraform/modules/validation-storage?ref=a5af379b7c47d353e7b1ff30700ad26c7b5105c1"

  project_id            = var.project_id
  region                = var.region
  zone                  = local.zone
  network_id            = module.networking.network_id
  subnet_id             = module.networking.subnet_id
  name_prefix           = local.name_prefix
  hostname              = "valstorage.${local.dns_domain}"
  terraform_ci_sa_email = "dep-dlm-terraform-ci@${var.project_id}.iam.gserviceaccount.com"
  certs_secret_id       = google_secret_manager_secret.valstorage_certs.id
  dns_zone_name         = google_dns_managed_zone.internal.name
  # Terraform downloads the whole testbed repo here, so the configs/,
  # scripts/ and patches/ the module embeds are available.
  repo_root = abspath("${path.root}/.terraform/modules/validation_storage")

  oidc_issuer       = var.oidc_issuer
  oidc_issuer_name  = var.oidc_issuer_name
  teapot_idp_name   = var.teapot_idp_name
  teapot_audiences  = var.teapot_audiences
  teapot_extra_subs = var.teapot_extra_subs

  labels = {
    environment = var.environment
    component   = "validation-storage"
  }

  # The VM pulls its certificates at first boot.
  depends_on = [google_secret_manager_secret_version.valstorage_certs]
}
