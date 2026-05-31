variable "name" {
  type        = string
  description = "Application-specific name suffix (e.g., dashboard-api, metrics-producer)."
}

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
  description = "Unique suffix for resource naming (e.g., hash of workload-environment)."
}

variable "container_name" {
  type = string
}

variable "image" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "revision_mode" {
  type    = string
  default = "Single"
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 1
}

variable "ingress_enabled" {
  type    = bool
  default = true
}

variable "target_port" {
  type    = number
  default = 8080
}

variable "environment_variables" {
  type    = map(string)
  default = {}
}

variable "secret_name" {
  type = string
}

variable "secret_value" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
