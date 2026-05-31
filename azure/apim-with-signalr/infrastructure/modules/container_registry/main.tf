resource "azurerm_container_registry" "this" {
  # ACR names must be lowercase alphanumeric, no hyphens
  # Pattern: acr[workload][environment][suffix]
  name                = lower(replace("acr${var.workload}${var.environment}${var.name_suffix}", "-", ""))
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}
