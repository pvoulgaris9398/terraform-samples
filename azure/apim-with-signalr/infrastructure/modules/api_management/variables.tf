variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "publisher_name" {
  type    = string
  default = "Example"
}

variable "publisher_email" {
  type    = string
  default = "admin@example.com"
}

variable "sku_name" {
  type    = string
  default = "Consumption_0"
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "name_suffix" {
  type    = string
  default = ""
}
