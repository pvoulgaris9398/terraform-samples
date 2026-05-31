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

variable "sku_name" {
  type    = string
  default = "Free_F1"
}

variable "capacity" {
  type    = number
  default = 1
}

variable "service_mode" {
  type    = string
  default = "Serverless"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "name_suffix" {
  type    = string
  default = ""
}
