output "web_app_default_hostname" {
  value = azurerm_linux_web_app.web.default_hostname
}

output "app_service_plan_id" {
  value = azurerm_service_plan.web.id
}

output "web_app_name" {
  value = azurerm_linux_web_app.web.name
}
