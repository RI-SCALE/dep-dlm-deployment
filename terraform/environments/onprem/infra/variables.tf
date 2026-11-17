variable "project_id" {
  description = "Testbed staging project (testbed bootstrap output project_ids.staging)"
  type        = string
}

variable "region" {
  description = "GCP region (testbed bootstrap output regions.staging)"
  type        = string
}

variable "environment" {
  description = "Environment name, used in resource names"
  type        = string
  default     = "onprem"
}

variable "subnet_cidr" {
  type    = string
  default = "10.40.0.0/24"
}

variable "node_internal_ip" {
  description = "Fixed node IP: Vault certificate SAN (VAULT_SAN), database host and Vault address in the GitOps values"
  type        = string
  default     = "10.40.0.10"
}

variable "certs_dir" {
  description = "The testbed's certs/ after `make certs` with VAULT_SAN and the validation storage's hostname in VALSTORAGE_EXTERNAL_SAN (absolute path)"
  type        = string
}

variable "public_ports" {
  description = "TCP ports opened to the internet on the node (80: the Gateway in front of Rucio)"
  type        = list(string)
  default     = ["80"]
}

# --- Validation storage (testbed modules/validation-storage) ----------------

variable "oidc_issuer" {
  description = "External OIDC issuer Teapot/XRootD trust (same as the vault root's)"
  type        = string
}

variable "oidc_issuer_name" {
  description = "Short label for oidc_issuer (egi-checkin-dev, lsaai-dev)"
  type        = string
}

variable "teapot_idp_name" {
  description = "IdP_name_1 in Teapot's STORAGE_AREA_1 (testbed staging uses egi)"
  type        = string
  default     = "egi"
}

variable "teapot_audiences" {
  description = "Audiences Teapot restricts the issuer's tokens to (LS AAI only)"
  type        = list(string)
  default     = []
}

variable "teapot_extra_subs" {
  description = "Extra subs mapped to Teapot's local user (client_credentials sub, human subs)"
  type        = list(string)
  default     = []
}
