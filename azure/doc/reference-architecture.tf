# ==============================================================================
# 1. CORE NETWORK ACCESS VARIABLES
# ==============================================================================
# Replace with your actual home public IPv4 address (find it via 'whatsmyip' on Google)
variable "my_home_ip" {
  type        = string
  description = "The specific public IP allowed to reach the APIM gateway."
  default     = "198.51.100.42" # <--- EDIT THIS WITH YOUR HOME IP
}

# ==============================================================================
# 2. PREREQUISITES & BASE MODULES (Maintained from previous steps)
# ==============================================================================
terraform {
  required_providers {
    azurerm = { source = "hashicorp/azurerm", version = "~> 3.0" }
    random  = { source = "hashicorp/random", version = "~> 3.0" }
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

variable "project" {
  type    = string
  default = "crm"
}
variable "environment" {
  type    = string
  default = "prod"
}
variable "location" {
  type    = string
  default = "eastus"
}

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
  default_tags      = { Environment = var.environment, WorkloadName = var.project, ManagedBy = "Terraform" }
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
# 3. BACKEND SECURITY LOCKDOWN: CONTAINER APP IP RESTRICTIONS
# ==============================================================================
resource "azurerm_container_app" "ca" {
  name                         = local.ca_name_truncated
  container_app_environment_id = azurerm_container_app_environment.cae.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"
  tags                         = local.default_tags

  identity { type = "SystemAssigned" }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }

    # CRITICAL SECURITY RULE: Drop everything except traffic originating from APIM
    ip_security_restriction {
      name        = "Allow-Only-APIM-Gateway"
      description = "Blocks public traffic. Only allows the dedicated public IP of our APIM instance."
      action      = "Allow" # Enforces default-deny on anything unmatched

      # Dynamically extracts the single output IP list string and translates to CIDR
      ip_address_range = "${azurerm_api_management.apim.public_ip_addresses[0]}/32"
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
# 4. STORAGE & VAULT LAYER (Maintained from previous step)
# ==============================================================================
resource "azurerm_cosmosdb_account" "cosmos" {
  name                = "cos-${substr(local.alphanumeric_base, 0, 40)}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"
  tags                = local.default_tags

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = azurerm_resource_group.rg.location
    failover_priority = 0
  }
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
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = data.azurerm_client_config.current.object_id
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
# 5. FRONT DOOR LOCKDOWN: APIM WITH HOME IP INBOUND POLICY
# ==============================================================================
resource "azurerm_api_management" "apim" {
  name                = "apim-${local.base_name}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  publisher_name      = "Enterprise IT"
  publisher_email     = "devops@example.com"
  sku_name            = "Developer_1"
  tags                = local.default_tags
}

resource "azurerm_api_management_api" "backend_api" {
  name                = "backend-service-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "Core Backend API"
  path                = "v1"
  protocols           = ["https"]
  service_url         = "https://${azurerm_container_app.ca.ingress[0].fqdn}"
}

resource "azurerm_api_management_api_operation" "catch_all" {
  operation_id        = "catch-all-routes"
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Catch All Ingress Routing"
  method              = "GET"
  url_template        = "/*"
}

resource "azurerm_api_management_api_policy" "routing_policy" {
  api_name            = azurerm_api_management_api.backend_api.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <!-- LAYER 1 SECURE FIREWALL: Denies execution unless request comes from Home IP -->
        <ip-filter action="allow">
            <address>${var.my_home_ip}</address>
        </ip-filter>
        
        <!-- Host Header Patching (Option B requirement) -->
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
    capacity = 1
    name     = "Free_F1"
  }
}

# ==============================================================================
# 1. SIGNALR APIM API DEFINITIONS
# ==============================================================================

# -- Part A: The HTTP Negotiate API Endpoint --
resource "azurerm_api_management_api" "signalr_negotiate" {
  name                = "signalr-negotiate-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "SignalR Handshake (Negotiate)"
  path                = "client/negotiate" # Exposed as: https://<apim-url>/client/negotiate
  protocols           = ["https"]

  # Routes the initial handshake authentication request down to the SignalR instance
  service_url = "https://${azurerm_signalr_service.signalr.hostname}/client/negotiate"
}

# Registers the required POST operation rule for SignalR negotiation
resource "azurerm_api_management_api_operation" "negotiate_post" {
  operation_id        = "signalr-negotiate-post"
  api_name            = azurerm_api_management_api.signalr_negotiate.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name
  display_name        = "Negotiate Handshake Authorization"
  method              = "POST"
  url_template        = "/"
}

# -- Part B: The Persistent WebSocket Tunnel API Endpoint --
resource "azurerm_api_management_api" "signalr_connect" {
  name                = "signalr-connect-api"
  resource_group_name = azurerm_resource_group.rg.name
  api_management_name = azurerm_api_management.apim.name
  revision            = "1"
  display_name        = "SignalR WebSocket Connection"
  path                = "client"      # Exposed as: wss://<apim-url>/client
  protocols           = ["wss", "ws"] # Enforces persistent duplex upgrade tunnels

  service_url = "wss://${azurerm_signalr_service.signalr.hostname}/client"
}


# ==============================================================================
# 2. FIREWALL & ROUTING POLICIES FOR SIGNALR PIPELINES
# ==============================================================================

# Protects the Negotiation API with your Home IP Lock
resource "azurerm_api_management_api_policy" "negotiate_policy" {
  api_name            = azurerm_api_management_api.signalr_negotiate.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <!-- LAYER 1 SECURE FIREWALL: Drops anyone who isn't trying to connect from your Home IP -->
        <ip-filter action="allow">
            <address>${var.my_home_ip}</address>
        </ip-filter>
        
        <!-- Appends the mandatory SignalR backend host header mapping -->
        <set-header name="Host" exists-action="override">
            <value>${azurerm_signalr_service.signalr.hostname}</value>
        </set-header>
    </inbound>
    <backend><base /></backend>
    <outbound><base /></outbound>
    <on-error><base /></on-error>
</policies>
XML
}

# Protects the WebSocket Tunnel API with your Home IP Lock
resource "azurerm_api_management_api_policy" "connect_policy" {
  api_name            = azurerm_api_management_api.signalr_connect.name
  api_management_name = azurerm_api_management.apim.name
  resource_group_name = azurerm_resource_group.rg.name

  xml_content = <<XML
<policies>
    <inbound>
        <base />
        <!-- LAYER 1 SECURE FIREWALL: Only allows the websocket handshake to occur from your Home IP -->
        <ip-filter action="allow">
            <address>${var.my_home_ip}</address>
        </ip-filter>
        
        <set-header name="Host" exists-action="override">
            <value>${azurerm_signalr_service.signalr.hostname}</value>
        </set-header>
    </inbound>
    <backend><base /></backend>
    <outbound><base /></outbound>
    <on-error><base /></on-error>
</policies>
XML
}

# ==============================================================================
# 3. COMPLEMENTARY OUTPUT STRINGS
# ==============================================================================
output "signalr_apim_negotiate_url" {
  value       = azurerm_api_management_api.signalr_negotiate.service_url
  description = "The gateway endpoint target for incoming real-time handshakes."
}

# ==============================================================================
# 7. POST-DEPLOYMENT OPERATIONAL OUTPUTS
# ==============================================================================
output "apim_public_gateway_url" {
  value       = "${azurerm_api_management.apim.gateway_url}/v1/"
  description = "The target endpoint URL you use to make API calls from home."
}

output "isolated_container_app_url" {
  value       = "https://${azurerm_container_app.ca.ingress[0].fqdn}"
  description = "The raw Container App URL. Testing this from home will return a network rejection, verifying your lockdown works."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "The URI of the created Azure Key Vault."
}
