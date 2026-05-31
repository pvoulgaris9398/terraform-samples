resource "azurerm_signalr_service" "this" {
  # Pattern: svc-[workload]-[environment]-[instance]
  # Example: svc-dashboard-dev-a1b2c
  name                = join("-", compact(["svc", var.workload, var.environment, var.name_suffix]))
  location            = var.location
  resource_group_name = var.resource_group_name

  sku {
    name     = var.sku_name
    capacity = var.capacity
  }

  service_mode = var.service_mode

  tags = var.tags
}
