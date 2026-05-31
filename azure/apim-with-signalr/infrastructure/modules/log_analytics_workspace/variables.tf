variable "workload" {
  type        = string
  description = "Workload name for resource naming (e.g., dashboard, api)."
}

variable "environment" {
  type        = string
  description = "Environment name for resource naming (e.g., dev, staging, prod)."
}

variable "name_suffix" {
  type        = string
  default     = ""
  description = "Unique suffix for resource naming (e.g., hash of resource group)."
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
