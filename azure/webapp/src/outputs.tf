output "resource_group_name" {
  value = module.resource_group.name
}

output "resource_group_location" {
  value = module.resource_group.location
}

output "virtual_network_id" {
  value = module.network.virtual_network_id
}

output "subnet_ids" {
  value = module.network.subnet_ids
}

output "web_app_default_hostname" {
  value = module.compute.web_app_default_hostname
}

output "postgres_flexible_server_fqdn" {
  value = module.database.postgres_flexible_server_fqdn
}

output "nat_gateway_public_ip" {
  value = module.network.nat_gateway_public_ip
}
