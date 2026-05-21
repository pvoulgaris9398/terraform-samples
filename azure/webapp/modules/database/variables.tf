variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "private_dns_zone_name" {
  type    = string
  default = "postgres.private"
}

variable "postgres" {
  type = object({
    admin_username = string
    admin_password = string
    version        = string
    sku_name       = string
    storage_mb     = number
    zone           = string
  })
  sensitive = true
}

variable "db_subnet_ids" {
  type = list(string)
}

variable "virtual_network_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
