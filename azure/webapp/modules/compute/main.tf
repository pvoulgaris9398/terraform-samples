resource "random_string" "webapp_suffix" {
  length  = var.suffix_length
  upper   = false
  lower   = true
  numeric = true
  special = false
}

resource "azurerm_service_plan" "web" {
  name                = "${var.name_prefix}-app-service-plan"
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = var.webapp.app_service_plan.os_type
  sku_name            = var.webapp.app_service_plan.sku_name
  tags                = var.tags
}

resource "azurerm_linux_web_app" "web" {
  name                = "${var.name_prefix}-webapp-${random_string.webapp_suffix.result}"
  location            = var.location
  resource_group_name = var.resource_group_name
  service_plan_id     = azurerm_service_plan.web.id
  tags                = var.tags

  site_config {
    linux_fx_version = var.webapp.linux_fx_version
  }

  app_settings = var.webapp.app_settings
}
