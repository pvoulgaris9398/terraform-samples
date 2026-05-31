resource "azurerm_resource_group" "this" {
  name     = join("-", compact(["rg", var.workload, var.environment, var.name_suffix]))
  location = var.location
  tags     = var.tags
}
