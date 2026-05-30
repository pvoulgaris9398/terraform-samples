variable "prefix" {
  type = string
}

variable "location" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "sku_name" {
  type    = string
  default = "Standard_S1"
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
