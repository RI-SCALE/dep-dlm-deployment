output "certs_key" {
  description = "secrets.certsKey"
  value       = module.vault_config.certs_key
}

output "config_key" {
  description = "secrets.configKey"
  value       = module.vault_config.config_key
}

output "vault_server" {
  description = "secretStore.vault.server"
  value       = local.infra.vault_addr
}

output "ca_bundle" {
  description = "secretStore.vault.caBundle (base64 of the testbed CA)"
  value       = base64encode(file("${var.certs_dir}/rucio_ca.pem"))
}

output "kubernetes_auth" {
  description = "secretStore.vault.kubernetesAuth"
  value = {
    mountPath = module.vault_config.kubernetes_auth_path
    role      = module.vault_config.role_name
  }
}
