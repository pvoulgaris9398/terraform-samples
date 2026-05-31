variable "location" {
  description = "Azure region where resources will be deployed. Use short region codes (e.g., eus, wus2, ukso)."
  default     = "eus"
}

variable "workload" {
  description = "Workload name for resource naming conventions. Used in resource names following CAF naming."
  default     = "dashboard"
}

variable "environment" {
  description = "Deployment environment (dev, staging, prod) for tagging and naming."
  default     = "dev"
}

variable "owner" {
  description = "Owner or team responsible for the resources."
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost center for billing and chargeback."
  default     = ""
}

variable "prefix" {
  description = "Legacy: Prefix used for resource naming. Consider using workload instead."
  default     = "realtimedemo"
}

variable "tags" {
  description = "Optional tags applied to all resources."
  type        = map(string)
  default     = {}
}

variable "publisher_name" {
  description = "Publisher name for API Management."
  default     = "Example"
}

variable "publisher_email" {
  description = "Publisher email for API Management."
  default     = "admin@example.com"
}

variable "dashboard_api_image" {
  description = "Container image used for the dashboard API."
  default     = "mcr.microsoft.com/dotnet/samples:aspnetapp"
}

variable "metrics_producer_image" {
  description = "Container image used for the metrics producer."
  default     = "mcr.microsoft.com/dotnet/samples:aspnetapp"
}

variable "dashboard_api_min_replicas" {
  description = "Minimum number of dashboard API container replicas."
  type        = number
  default     = 0
}

variable "dashboard_api_max_replicas" {
  description = "Maximum number of dashboard API container replicas."
  type        = number
  default     = 1
}

variable "metrics_producer_min_replicas" {
  description = "Minimum number of metrics producer container replicas."
  type        = number
  default     = 0
}

variable "metrics_producer_max_replicas" {
  description = "Maximum number of metrics producer container replicas."
  type        = number
  default     = 1
}
