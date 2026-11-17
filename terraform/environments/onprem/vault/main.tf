terraform {
  required_version = ">= 1.7"

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.0"
    }
  }
}

# Vault on the node is reachable only through an IAP tunnel
# (`make onprem-vault-apply` opens it); VAULT_TOKEN comes from the
# vault-init secret. Its certificate is from the testbed CA and lists
# localhost, so TLS verification works through the tunnel.
provider "vault" {
  address      = var.vault_addr
  ca_cert_file = "${var.certs_dir}/rucio_ca.pem"
}

data "terraform_remote_state" "infra" {
  backend = "gcs"
  config = {
    bucket = var.state_bucket
    prefix = "${var.environment}/infra"
  }
}

locals {
  infra = data.terraform_remote_state.infra.outputs
}

module "vault_config" {
  source = "../../../modules/vault-config"

  name_prefix        = "dep-dlm-${var.environment}"
  kubernetes_host    = "https://${local.infra.node_internal_ip}:6443"
  kubernetes_ca_cert = file(var.kubernetes_ca_cert_file)

  eso_service_account_name      = var.eso_service_account_name
  eso_service_account_namespace = var.eso_service_account_namespace

  certs_dir = var.certs_dir

  rucio_db_host     = local.infra.rucio_database_host
  rucio_db_password = local.infra.rucio_db_password
  fts_db_host       = local.infra.fts_database_host
  fts_db_password   = local.infra.fts_db_password
  storage_ip        = local.infra.valstorage_ip == "" ? null : local.infra.valstorage_ip

  rucio_host             = "http://${local.infra.rucio_public_hostname}"
  bootstrap_userpass_pwd = var.bootstrap_userpass_pwd
  userpass_password      = var.userpass_password
  oidc_issuer            = var.oidc_issuer
  oidc_client_id         = var.oidc_client_id
  oidc_client_secret     = var.oidc_client_secret
  oidc_expected_scope    = var.oidc_expected_scope
  oidc_expected_audience = var.oidc_expected_audience
  token_mode             = var.token_mode
  scope_profile          = var.scope_profile
}
