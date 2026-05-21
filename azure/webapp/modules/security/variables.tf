variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "name_prefix" {
  type = string
}

variable "subnet_ids" {
  type = map(list(string))
}

variable "subnet_prefixes" {
  type = map(list(string))
}

variable "tags" {
  type    = map(string)
  default = {}
}
