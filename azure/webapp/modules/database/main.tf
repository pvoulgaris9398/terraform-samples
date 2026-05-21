resource "azurerm_private_dns_zone" "postgres" {
  name                = var.private_dns_zone_name
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "postgres-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = var.virtual_network_id
}

resource "random_password" "postgres" {
  count            = var.postgres.admin_password == "" ? 1 : 0
  length           = 32
  special          = true
  override_special = "!@#$%&*()-_=+"
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "${var.name_prefix}-postgres-server"
  resource_group_name = var.resource_group_name
  location            = var.location

  administrator_login    = var.postgres.admin_username
  administrator_password = var.postgres.admin_password != "" ? var.postgres.admin_password : random_password.postgres[0].result

  sku_name   = var.postgres.sku_name
  version    = var.postgres.version
  storage_mb = var.postgres.storage_mb

  delegated_subnet_id = element(var.db_subnet_ids, 0)
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id
  zone                = var.postgres.zone

  high_availability {
    mode = "ZoneRedundant"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgres,
  ]
  tags = var.tags
}
