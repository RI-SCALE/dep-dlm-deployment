output "project_id" {
  value = var.project_id
}

output "region" {
  value = var.region
}

output "zone" {
  value = module.node.zone
}

output "node_name" {
  value = module.node.instance_name
}

output "node_external_ip" {
  value = module.node.external_ip
}

output "node_internal_ip" {
  value = module.node.internal_ip
}

output "rucio_database_host" {
  description = "bootstrapDb.dbHost"
  value       = module.node.internal_ip
}

output "rucio_db_password" {
  value     = module.node.rucio_db_password
  sensitive = true
}

output "fts_database_host" {
  value = module.node.internal_ip
}

output "fts_db_password" {
  value     = module.node.fts_db_password
  sensitive = true
}

output "vault_addr" {
  description = "secretStore.vault.server"
  value       = "https://${module.node.internal_ip}:8200"
}

output "vault_init_secret_id" {
  value = module.node.vault_init_secret_id
}

output "valstorage_hostname" {
  value = module.validation_storage.hostname
}

output "valstorage_ip" {
  value = module.validation_storage.external_ip
}

output "valstorage_instance_name" {
  value = module.validation_storage.instance_name
}

# For registering the RSEs
output "valstorage_pfn_roots" {
  value = {
    xrd3    = module.validation_storage.xrd3_pfn_root
    xrd4    = module.validation_storage.xrd4_pfn_root
    teapot1 = module.validation_storage.teapot1_pfn_root
    teapot2 = module.validation_storage.teapot2_pfn_root
  }
}

output "gateway_static_ip" {
  description = "Node's external IP: the Gateway (Traefik hostPort 80) serves Rucio there"
  value       = module.node.external_ip
}

output "rucio_public_hostname" {
  value = "rucio.${local.dns_domain}"
}

output "fts_public_hostname" {
  value = "fts.${local.dns_domain}"
}

output "validation_storage_ip" {
  value = module.validation_storage.external_ip
}

output "validation_storage_hostname" {
  value = module.validation_storage.hostname
}

output "validation_storage_xrd3_pfn_root" {
  value = module.validation_storage.xrd3_pfn_root
}

output "validation_storage_xrd4_pfn_root" {
  value = module.validation_storage.xrd4_pfn_root
}

output "validation_storage_teapot1_pfn_root" {
  value = module.validation_storage.teapot1_pfn_root
}

output "validation_storage_teapot2_pfn_root" {
  value = module.validation_storage.teapot2_pfn_root
}

output "rucio_database_private_ip" {
  value = module.node.internal_ip
}

output "fts_database_private_ip" {
  value = module.node.internal_ip
}
