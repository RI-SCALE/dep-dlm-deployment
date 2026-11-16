# ============================================================================
# vault-config — the Vault counterpart of the testbed's modules/secrets:
# the same two entries (certs, config) with the same keys and the same
# rendered files, written to Vault KV v2 instead of Secret Manager, plus
# Kubernetes auth for External Secrets. The chart is unchanged: only
# secretStore.provider and the two remote keys differ per environment.
#
# templates/ and profiles/ are copied from the testbed by `make sync`, at
# the same commit as charts/dep-dlm/files/.
# ============================================================================

terraform {
  required_providers {
    vault = {
      source = "hashicorp/vault"
    }
  }
}

resource "vault_mount" "kv" {
  path        = var.kv_mount
  type        = "kv"
  options     = { version = "2" }
  description = "dep-dlm secrets read by External Secrets"
}

# --- Kubernetes auth for External Secrets ------------------------------------
# Vault runs outside the cluster, so it validates ESO's service-account
# token with the TokenReview API using that same token
# (disable_local_ca_jwt, no reviewer JWT). That needs the ESO service
# account bound to system:auth-delegator, which the chart creates for
# secretStore.provider=vault.

resource "vault_auth_backend" "kubernetes" {
  type = "kubernetes"
  path = var.kubernetes_auth_path
}

resource "vault_kubernetes_auth_backend_config" "this" {
  backend              = vault_auth_backend.kubernetes.path
  kubernetes_host      = var.kubernetes_host
  kubernetes_ca_cert   = var.kubernetes_ca_cert
  disable_local_ca_jwt = true
}

resource "vault_policy" "read" {
  name   = "${var.name_prefix}-read"
  policy = <<-EOT
    path "${var.kv_mount}/data/${var.name_prefix}/*" {
      capabilities = ["read"]
    }
    path "${var.kv_mount}/metadata/${var.name_prefix}/*" {
      capabilities = ["read", "list"]
    }
  EOT
}

resource "vault_kubernetes_auth_backend_role" "eso" {
  backend                          = vault_auth_backend.kubernetes.path
  role_name                        = var.role_name
  bound_service_account_names      = [var.eso_service_account_name]
  bound_service_account_namespaces = [var.eso_service_account_namespace]
  token_policies                   = [vault_policy.read.name]
  token_ttl                        = 3600
}
