# A plain VPC for the single on-premise-style node. No GKE secondary
# ranges and no private-services peering: databases and Vault run on the
# node itself, the way they would sit next to a partner's cluster.

resource "google_compute_network" "this" {
  name                    = "${var.name_prefix}-vpc"
  project                 = var.project_id
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "this" {
  name                     = "${var.name_prefix}-subnet"
  project                  = var.project_id
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true
}

# SSH (22), kube-apiserver (6443) and Vault (8200) only through IAP:
# 35.235.240.0/20 is Google's range reserved for IAP TCP forwarding, and
# IAP enforces roles/iap.tunnelResourceAccessor before proxying. Nothing
# administrative is exposed to the internet.
resource "google_compute_firewall" "iap_admin" {
  name    = "${var.name_prefix}-iap-admin"
  project = var.project_id
  network = google_compute_network.this.id

  allow {
    protocol = "tcp"
    ports    = ["22", "6443", "8200"]
  }

  source_ranges = ["35.235.240.0/20"]
  target_tags   = [var.node_tag]
}

# Optional public service ports (e.g. 80/443 once an ingress controller
# exposes Rucio/FTS). Empty by default.
resource "google_compute_firewall" "public_ingress" {
  count   = length(var.public_ports) > 0 ? 1 : 0
  name    = "${var.name_prefix}-public-ingress"
  project = var.project_id
  network = google_compute_network.this.id

  allow {
    protocol = "tcp"
    ports    = var.public_ports
  }

  source_ranges = var.public_source_ranges
  target_tags   = [var.node_tag]
}
