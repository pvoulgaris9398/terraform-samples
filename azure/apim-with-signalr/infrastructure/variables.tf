variable "location" {
  description = "Azure region where resources will be deployed."
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the Azure resource group."
  default     = "rg-realtime-dashboard"
}

variable "prefix" {
  description = "Prefix used for all resource naming."
  default     = "realtimedemo"
}

variable "environment" {
  description = "Deployment environment for tagging."
  default     = "dev"
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
