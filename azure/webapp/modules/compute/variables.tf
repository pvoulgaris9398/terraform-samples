variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "webapp" {
  type = object({
    linux_fx_version = string
    app_service_plan = object({
      os_type  = string
      sku_name = string
    })
    app_settings = map(string)
  })
}

variable "suffix_length" {
  type    = number
  default = 6
}

variable "tags" {
  type    = map(string)
  default = {}
}
