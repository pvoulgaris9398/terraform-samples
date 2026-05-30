output "id" {
  value = azurerm_signalr_service.this.id
}

output "primary_connection_string" {
  value     = azurerm_signalr_service.this.primary_connection_string
  sensitive = true
}
