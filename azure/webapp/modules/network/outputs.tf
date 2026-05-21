output "virtual_network_id" {
  value = azurerm_virtual_network.main.id
}

output "subnet_ids" {
  value = local.subnet_ids_by_type
}

output "subnet_prefixes" {
  value = local.subnet_prefixes_by_type
}

output "nat_gateway_public_ip" {
  value = azurerm_public_ip.nat.ip_address
}
