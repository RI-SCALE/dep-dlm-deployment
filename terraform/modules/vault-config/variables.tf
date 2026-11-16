variable "name_prefix" {
  description = "Path prefix of the two KV entries (<prefix>/certs, <prefix>/config) and the policy name"
  type        = string
}

variable "kv_mount" {
  description = "KV v2 mount (secretStore.vault.path in the GitOps values)"
  type        = string
  default     = "secret"
}

variable "kubernetes_auth_path" {
  description = "Kubernetes auth mount (secretStore.vault.kubernetesAuth.mountPath)"
  type        = string
  default     = "kubernetes"
}

variable "role_name" {
  description = "Kubernetes auth role (secretStore.vault.kubernetesAuth.role)"
  type        = string
  default     = "dep-dlm"
}

variable "kubernetes_host" {
  description = "kube-apiserver URL as Vault reaches it (the node's internal IP)"
  type        = string
}

variable "kubernetes_ca_cert" {
  description = "PEM of the cluster CA (/etc/kubernetes/pki/ca.crt)"
  type        = string
}

variable "eso_service_account_name" {
  description = "External Secrets service account (env.yaml eso.name)"
  type        = string
}

variable "eso_service_account_namespace" {
  description = "Its namespace (env.yaml eso.namespace)"
  type        = string
}

variable "certs_dir" {
  description = "The testbed's certs/ directory (make certs): host certificate, CA, signing policy"
  type        = string
}

# --- Rendered content: same variables as the testbed's modules/secrets ------

variable "rucio_db_host" {
  type = string
}

variable "rucio_db_password" {
  type      = string
  sensitive = true
}

variable "fts_db_host" {
  type = string
}

variable "fts_db_password" {
  type      = string
  sensitive = true
}

variable "rucio_host" {
  description = "Base URL the Rucio client/auth host point at"
  type        = string
  default     = "http://rucio-server"
}

variable "bootstrap_userpass_pwd" {
  type      = string
  sensitive = true
}

variable "userpass_username" {
  type    = string
  default = "ddmlab"
}

variable "userpass_account" {
  type    = string
  default = "ddmlab"
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

variable "oidc_client_account" {
  type    = string
  default = "randomaccount"
}

variable "token_mode" {
  type    = string
  default = "managed"
  validation {
    condition     = contains(["managed", "unmanaged"], var.token_mode)
    error_message = "token_mode must be 'managed' or 'unmanaged'."
  }
}

variable "scope_profile" {
  description = "IdP profile under profiles/ (egi-dev, ls-aai-dev)"
  type        = string
}

variable "site_name" {
  type    = string
  default = "DOCKER"
}

variable "storage_ip" {
  description = "Validation-storage IP (valstorage-ip key); null: omitted"
  type        = string
  default     = null
}
