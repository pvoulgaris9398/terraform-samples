output "dashboard_api_url" {
  value = module.dashboard_api.fqdn
}

output "metrics_producer_url" {
  value = module.metrics_producer.fqdn
}

output "api_management_portal_url" {
  value = module.api_management.portal_url
}
