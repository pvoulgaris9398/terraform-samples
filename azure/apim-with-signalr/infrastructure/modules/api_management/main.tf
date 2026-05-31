resource "azurerm_api_management" "this" {
  # Pattern: apim-[workload]-[environment]-[instance]
  # Example: apim-dashboard-dev-a1b2c
  name                = join("-", compact(["apim", var.workload, var.environment, var.name_suffix]))
  location            = var.location
  resource_group_name = var.resource_group_name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  sku_name            = var.sku_name
  tags                = var.tags
}
