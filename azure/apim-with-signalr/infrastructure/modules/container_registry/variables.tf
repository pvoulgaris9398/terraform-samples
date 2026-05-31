variable "workload" {
  type        = string
  description = "Workload name for resource naming (e.g., dashboard, api)."
}

variable "environment" {
  type        = string
  description = "Environment name for resource naming (e.g., dev, staging, prod)."
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku" {
  type    = string
  default = "Basic"
}

variable "admin_enabled" {
  type    = bool
  default = true
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "name_suffix" {
  type    = string
  default = ""
}
