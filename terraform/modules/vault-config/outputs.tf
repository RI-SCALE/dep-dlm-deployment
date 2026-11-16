output "certs_key" {
  description = "secrets.certsKey in the GitOps values"
  value       = vault_kv_secret_v2.certs.name
}

output "config_key" {
  description = "secrets.configKey in the GitOps values"
  value       = vault_kv_secret_v2.config.name
}

output "kv_mount" {
  value = vault_mount.kv.path
}

output "kubernetes_auth_path" {
  value = vault_auth_backend.kubernetes.path
}

output "role_name" {
  value = vault_kubernetes_auth_backend_role.eso.role_name
}
