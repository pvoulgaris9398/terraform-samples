resource "azurerm_log_analytics_workspace" "this" {
  name                = join("-", compact(["law", var.workload, var.environment, var.name_suffix]))
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = var.tags
}
