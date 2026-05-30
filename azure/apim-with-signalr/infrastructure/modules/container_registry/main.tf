resource "azurerm_container_registry" "this" {
  name                = "${var.prefix}acr"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = var.sku
  admin_enabled       = var.admin_enabled
  tags                = var.tags
}
