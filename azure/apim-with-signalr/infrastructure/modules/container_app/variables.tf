variable "name" {
  type = string
}

variable "prefix" {
  type = string
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
  default = 1
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
