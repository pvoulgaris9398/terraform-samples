variable "name_prefix" {
  type    = string
  default = "three-tier"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "East US"
}

variable "resource_group_name" {
  type    = string
  default = ""
}

variable "common_tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
}

variable "vnet" {
  type = object({
    cidr                  = string
    address_prefix_length = number
    subnets = map(object({
      address_prefix_offset = number
      service_delegation = optional(object({
        name    = string
        actions = list(string)
      }))
    }))
  })
  default = {
    cidr                  = "10.0.0.0/16"
    address_prefix_length = 8
    subnets = {
      web = {
        address_prefix_offset = 0
      }
      api = {
        address_prefix_offset = 10
      }
      db = {
        address_prefix_offset = 20
        service_delegation = {
          name = "Microsoft.DBforPostgreSQL/flexibleServers"
          actions = [
            "Microsoft.Network/virtualNetworks/subnets/join/action"
          ]
        }
      }
    }
  }
}

variable "az_count" {
  type    = number
  default = 2
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
  default = {
    admin_username = "pgadmin"
    admin_password = ""
    version        = "16"
    sku_name       = "GP_Standard_D2s_v3"
    storage_mb     = 32768
    zone           = "1"
  }
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
  default = {
    linux_fx_version = "DOCKER|mcr.microsoft.com/dotnet/samples:aspnetapp"
    app_service_plan = {
      os_type  = "Linux"
      sku_name = "S1"
    }
    app_settings = {
      WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"
    }
  }
}
