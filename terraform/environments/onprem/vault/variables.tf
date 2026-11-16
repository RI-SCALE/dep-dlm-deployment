variable "state_bucket" {
  description = "Testbed staging state bucket (testbed bootstrap output state_buckets.staging), to read ../infra's outputs"
  type        = string
}

variable "environment" {
  type    = string
  default = "onprem"
}

variable "vault_addr" {
  description = "Vault as reached through the IAP tunnel"
  type        = string
  default     = "https://localhost:18200"
}

variable "certs_dir" {
  description = "The testbed's certs/ (absolute path): CA for the provider, host certificate for the certs entry"
  type        = string
}

variable "kubernetes_ca_cert_file" {
  description = "Cluster CA written by scripts/fetch-kubeconfig.sh"
  type        = string
}

variable "eso_service_account_name" {
  description = "Must match environments/reference-onprem/staging/env.yaml eso.name"
  type        = string
  default     = "external-secrets"
}

variable "eso_service_account_namespace" {
  description = "Must match env.yaml eso.namespace"
  type        = string
  default     = "external-secrets"
}

variable "rucio_host" {
  type    = string
  default = "http://rucio-server"
}

variable "bootstrap_userpass_pwd" {
  type      = string
  sensitive = true
}

variable "userpass_password" {
  type      = string
  sensitive = true
}

variable "oidc_issuer" {
  type = string
}

variable "oidc_client_id" {
  type = string
}

variable "oidc_client_secret" {
  type      = string
  sensitive = true
}

variable "oidc_expected_scope" {
  type    = string
  default = "openid offline_access storage.read:/ storage.modify:/"
}

variable "oidc_expected_audience" {
  type    = string
  default = "https://fts.example.org/"
}

variable "token_mode" {
  type    = string
  default = "managed"
}

variable "scope_profile" {
  description = "egi-dev | ls-aai-dev"
  type        = string
}
