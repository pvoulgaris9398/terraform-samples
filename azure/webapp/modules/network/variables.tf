variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "vnet_cidr" {
  type = string
}

variable "address_prefix_length" {
  type    = number
  default = 8
}

variable "az_count" {
  type    = number
  default = 2
}

variable "subnets" {
  type = map(object({
    address_prefix_offset = number
    service_delegation = optional(object({
      name    = string
      actions = list(string)
    }))
  }))
}

variable "tags" {
  type    = map(string)
  default = {}
}
