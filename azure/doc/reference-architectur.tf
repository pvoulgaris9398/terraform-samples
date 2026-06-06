# ==============================================================================
# 1. CORE PROVIDERS & CONFIGURATION
# ==============================================================================
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
  }
}

variable "project"     { type = string; default = "crm" }
variable "environment" { type = string; default = "prod" }
variable "location"    { type = string; default = "eastus" }

resource "random_string" "suffix" {
  length  = 4
  upper   = false
  special = false
}

data "azurerm_client_config" "current" {}

locals {
  region_short      = replace(replace(var.location, "eastus", "eus"), "westus", "wus")
  base_name         = "${var.project}-${var.environment}-${local.region_short}-${random_string.suffix.result}"
  alphanumeric_base = lower(replace(local.base_name, "-", ""))
  
  ca_project_max    = substr(var.project, 0, 10)
  ca_name_truncated = "ca-${local.ca_project_max}-${var.environment}-${local.region_short}-${random_string.suffix.result}"

  default_tags = {
    Environment  = var.environment
    WorkloadName = var.project
    ManagedBy    = "Terraform"
  }
}

# ==============================================================================
# 2. BASELINE RESOURCES & LOGGING
# ==============================================================================
resource "azurerm_resource_group" "rg" {
  name     = "rg-${local.base_name}"
  location = var.location
  tags     = local.default_tags
}

resource "azurerm_log_analytics_workspace" "law" {
  name                = "log-${local.base_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  tags                = local.default_tags
}

# ==============================================================================
# 3. CONTAINER APP ENVIRONMENT & CONTAINER (Option A)
# ==============================================================================
resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${local.base_name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.default_tags
}

resource "azurerm_container_app" "ca" {
  name                         = local.ca_name_truncated
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.default_tags

  identity {
    type = "SystemAssigned"
  }

  ingress {
    external_enabled = true # Must be enabled for APIM to reach it over public IP
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  template {
    container {
      name   = "web-app"
      image  = "://microsoft.com"
      cpu    = "0.25"
      memory = "0.5Gi"

      env {
        name  = "COSMOS_SECRET_URL"
        value = azurerm_key_vault_secret.cosmos_connection_string.id
      }
    }
  }
}

# ==============================================================================
# 4. STORAGE, KEY VAULT & ACCESS POLICIES
# ==============================================================================
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cos-${substr(local.alphanumeric_base, 0, 40)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  tags                = local.default_tags

  consistency_policy { consistency_level = "Session" }
  geo_location       { location = azurerm_resource_group.rg.location; failover_priority = 0 }
}

resource "azurerm_key_vault" "kv" {
  name                        = "kv-${substr(local.alphanumeric_base, 0, 21)}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = local.default_tags

  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

resource "azurerm_key_vault_access_policy" "ca_policy" {
  key_vault_id       = azurerm_key_vault.kv.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_container_app.ca.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-primary-connection-string"
  value        = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}

# ==============================================================================
# 5. API MANAGEMENT (APIM) ROUTING STRUCTURE (Option B)
# ==============================================================================
resource "azurerm_api_management" "apim" {
  name                = "apim-${local.base_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Enterprise IT"
  publisher_email     = "devops@example.com"
  sku_name            = "Developer_1" # Use Developer SKU for testing cost efficiency
  tags                = local.default_tags
}

# Creates a logical API grouping inside APIM
resource "azurerm_api_management_api" "backend_api" {
  name                = "backend-service-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Core Backend API"
  path                = "v1" # Endpoints expose as: https://azure-api.net...
  protocols           = ["https"]
  
  # Dynamically points APIM directly at your Container App target URL
  service_url         = "https://${azurerm_container_app.ca.ingress[0].fqdn}"
}

# Exposes a test wildcard route that passes all sub-paths directly to the container
resource "azurerm_api_management_api_operation" "catch_all" {
  operation_id        = "catch-all-routes"
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Catch All Ingress Routing"
  method              = "GET"
  url_template        = "/*"
}

# CRITICAL POLICY: Rewrites the Host header to fix the Azure Container App routing 404 issue.
resource "azurerm_api_management_api_policy" "routing_policy" {
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <!-- Fixes Host header mismatch by forcing it to match the Container App FQDN -->
        <set-header name="X-Forwarded-Host" exists-action="override">
            <value>@(context.Request.Headers.GetValueOrDefault("Host"))</value>
        </set-header>
        <set-header name="Host" exists-action="override">
            <value>${azurerm_container_app.ca.ingress[0].fqdn}</value>
        </set-header>
    </inbound>
    <backend>
        <base />
    </backend>
    <outbound>
        <base />
    </outbound>
    <on-error>
        <base />
    </on-error>
</policies>
XML
}

# ==============================================================================
# 6. REAL-TIME SIGNALR CORE INFRASTRUCTURE
# ==============================================================================
resource "azurerm_signalr_service" "signalr" {
  name                = "sigr-${local.base_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.default_tags

  sku {
    name     = "Free_F1"
    capacity = 1
  }
}
