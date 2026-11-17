variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "GCP region for the static addresses"
  type        = string
}

variable "zone" {
  description = "GCP zone for the VM"
  type        = string
}

variable "name_prefix" {
  description = "Prefix for all resources (e.g. dep-dlm-onprem)"
  type        = string
}

variable "subnet_id" {
  description = "Subnetwork the VM attaches to (module.networking)"
  type        = string
}

variable "subnet_cidr" {
  description = "CIDR of that subnet; PostgreSQL accepts connections from it"
  type        = string
}

variable "node_tag" {
  description = "Network tag matching the networking module's firewall rules"
  type        = string
}

variable "internal_ip" {
  description = "Fixed internal IP of the node. Must be inside subnet_cidr and in VAULT_SAN of the Vault certificate."
  type        = string
  default     = "10.40.0.10"
}

variable "machine_type" {
  description = "4 vCPU / 16 GB fits Kubernetes, Rucio, FTS, OPA, both databases and Vault"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  type    = number
  default = 100
}

variable "image" {
  description = "Boot image. Ubuntu LTS: a common on-premise base, unlike Container-Optimized OS."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "kubernetes_minor" {
  description = "Kubernetes minor version for the pkgs.k8s.io apt repository (e.g. 1.36)"
  type        = string
  default     = "1.36"
}

variable "kubernetes_version" {
  description = "kubeadm kubernetesVersion; must belong to kubernetes_minor"
  type        = string
  default     = "v1.36.0"
}

variable "pod_cidr" {
  description = "Pod network (Flannel's default). PostgreSQL accepts connections from it."
  type        = string
  default     = "10.244.0.0/16"
}

variable "service_cidr" {
  type    = string
  default = "10.96.0.0/12"
}

variable "flannel_version" {
  description = "Flannel release whose kube-flannel.yml is applied"
  type        = string
  default     = "v0.26.1"
}

variable "local_path_version" {
  description = "rancher/local-path-provisioner release (default StorageClass)"
  type        = string
  default     = "v0.0.30"
}

variable "certs_dir" {
  description = "Directory with vaultcert.pem, vaultkey.pem and rucio_ca.pem (the testbed's certs/ after `VAULT_SAN=<internal_ip> make certs`)"
  type        = string

  validation {
    condition     = fileexists("${var.certs_dir}/vaultcert.pem") && fileexists("${var.certs_dir}/vaultkey.pem") && fileexists("${var.certs_dir}/rucio_ca.pem")
    error_message = "certs_dir must contain vaultcert.pem, vaultkey.pem and rucio_ca.pem: run make onprem-vault-cert first."
  }
}

variable "valstorage_hostname" {
  description = "Validation-storage hostname, added to CoreDNS (hosts block) so pods resolve it independently of the VPC's DNS. Empty: skip."
  type        = string
  default     = ""
}

variable "valstorage_ip" {
  description = "Validation-storage IP for that CoreDNS entry"
  type        = string
  default     = ""
}

variable "terraform_ci_sa_email" {
  description = "CI service account that creates the VM (granted serviceAccountUser on the node SA). null: local applies only."
  type        = string
  default     = null
}

variable "labels" {
  type    = map(string)
  default = {}
}

variable "gateway_api_version" {
  description = "Gateway API release whose standard CRDs are installed (Traefik implements them)"
  type        = string
  default     = "v1.5.1" # Traefik v3.7 needs TLSRoute v1 (Standard since v1.5)
}
