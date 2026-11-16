variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the subnet"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all networking resource names (e.g. dep-dlm-onprem)"
  type        = string
}

variable "subnet_cidr" {
  description = "Primary CIDR of the node subnet. Must contain the node's fixed internal IP."
  type        = string
  default     = "10.40.0.0/24"
}

variable "node_tag" {
  description = "Network tag the firewall rules target"
  type        = string
}

variable "public_ports" {
  description = "TCP ports opened to public_source_ranges (empty: none)"
  type        = list(string)
  default     = []
}

variable "public_source_ranges" {
  description = "Source ranges for public_ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
