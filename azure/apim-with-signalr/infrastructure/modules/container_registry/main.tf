resource "azurerm_container_registry" "this" {
  name                = lower(replace("${var.prefix}${var.name_suffix}acr", "-", ""))
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}
