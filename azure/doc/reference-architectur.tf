# ==============================================================================
# 1. PREREQUISITES (Carried over from previous steps)
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

resource "azurerm_container_app_environment" "cae" {
  name                       = "cae-${local.base_name}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id
  tags                       = local.default_tags
}

# ==============================================================================
# 2. CONTAINER APP WITH MANAGED IDENTITY
# ==============================================================================
resource "azurerm_container_app" "ca" {
  name                         = local.ca_name_truncated
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.default_tags

  # CRITICAL: This enables the System-Assigned Managed Identity for the app
  identity {
    type = "SystemAssigned"
  }

  template {
    container {
      name   = "web-app"
      image  = "://microsoft.com"
      cpu    = "0.25"
      memory = "0.5Gi"

      # Pass the Key Vault Secret URL to your code as an Environment Variable
      env {
        name  = "COSMOS_SECRET_URL"
        value = azurerm_key_vault_secret.cosmos_connection_string.id
      }
    }
  }
}

# ==============================================================================
# 3. STORAGE & VAULT INFRASTRUCTURE
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

  # Policy 1: Allows your Terraform pipeline runner to create/delete secrets
  access_policy {
    tenant_id = data.azurerm_client_config.current.tenant_id
    object_id = data.azurerm_client_config.current.object_id
    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# Policy 2: Explicitly allows the Container App to READ secrets
# Separating this into its own block avoids circular dependencies in Terraform
resource "azurerm_key_vault_access_policy" "ca_policy" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  
  # Fetches the identity dynamically generated by the Container App
  object_id    = azurerm_container_app.ca.identity[0].principal_id

  secret_permissions = [
    "Get",
    "List"
  ]
}

resource "azurerm_key_vault_secret" "cosmos_connection_string" {
  name         = "cosmos-primary-connection-string"
  value        = azurerm_cosmosdb_account.cosmos.primary_sql_connection_string
  key_vault_id = azurerm_key_vault.kv.id
}
