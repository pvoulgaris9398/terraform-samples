# Create an Azure AD Application Registration for Grafana Connection
resource "azuread_application" "grafana_oss" {
  display_name = "app-grafana-observability-${var.environment}"
}

resource "azuread_service_principal" "grafana_sp" {
  client_id                    = azuread_application.grafana_oss.client_id
  app_role_assignment_required = false
}

# Generate a secure password for the Grafana Azure Monitor plugin
resource "azuread_service_principal_password" "grafana_secret" {
  service_principal_id = azuread_service_principal.grafana_sp.id
}

# Assign the 'Monitoring Reader' role to the Grafana Principal over your Resource Group
resource "azurerm_role_assignment" "grafana_monitoring" {
  scope                = azurerm_resource_group.rg.id
  role_definition_name = "Monitoring Reader"
  principal_id         = azuread_service_principal.grafana_sp.id
}

# ------------------------------------------------------------------------------
# OPERATIONAL OUTPUTS FOR GRAFANA CONFIGURATION
# ------------------------------------------------------------------------------
output "grafana_azure_monitor_config" {
  value = {
    tenant_id     = data.azurerm_client_config.current.tenant_id
    subscription  = data.azurerm_client_config.current.subscription_id
    client_id     = azuread_application.grafana_oss.client_id
    client_secret = azuread_service_principal_password.grafana_secret.value
  }
  sensitive = true # Keeps credentials hidden during raw console logs
}
