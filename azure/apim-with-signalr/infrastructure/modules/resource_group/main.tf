resource "azurerm_resource_group" "this" {
  name     = join("-", compact(["rg", var.workload, var.environment]))
  location = var.location
  tags     = var.tags
}
