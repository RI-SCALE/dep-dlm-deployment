output "instance_name" {
  value = google_compute_instance.this.name
}

output "zone" {
  value = google_compute_instance.this.zone
}

output "external_ip" {
  value = google_compute_address.external.address
}

output "internal_ip" {
  description = "Node IP: Rucio/FTS database host and Vault address for the GitOps values"
  value       = google_compute_address.internal.address
}

output "service_account_email" {
  value = google_service_account.node.email
}

output "rucio_db_password" {
  value     = random_password.rucio_db.result
  sensitive = true
}

output "fts_db_password" {
  value     = random_password.fts_db.result
  sensitive = true
}

output "vault_init_secret_id" {
  description = "Secret Manager secret scripts/vault-init.sh stores the init output in"
  value       = google_secret_manager_secret.vault_init.id
}
