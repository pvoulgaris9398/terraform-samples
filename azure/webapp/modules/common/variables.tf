variable "name_prefix" {
  type    = string
  default = "three-tier"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "location" {
  type    = string
  default = "East US"
}

variable "common_tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}
