# ==============================================================================
# CONTAINER ENVIRONMENT DIAGNOSTIC SETTINGS (Streaming Logs to Log Analytics)
# ==============================================================================
resource "azurerm_monitor_diagnostic_setting" "cae_logging" {
  name = "ds-${local.base_name}-logging"

  # Crucial: Target the Environment ID where the apps execute, not the individual apps
  target_resource_id         = azurerm_container_app_environment.cae.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  # Captures standard stdout/stderr application console prints
  enabled_log {
    category = "ContainerAppConsoleLogs"
  }

  # Captures internal scaling, crashloop, deployment, and health check events
  enabled_log {
    category = "ContainerAppSystemLogs"
  }

  # Captures fine-grained traffic metrics for advanced performance dashboards
  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
