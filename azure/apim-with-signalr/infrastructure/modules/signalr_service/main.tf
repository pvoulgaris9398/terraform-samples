resource "azurerm_signalr_service" "this" {
  name                = "${var.prefix}-signalr"
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name
    capacity = var.capacity
  }

  service_mode = var.service_mode

  tags = var.tags
}
