locals {
  common_tags = merge(var.tags, {
    Project     = var.prefix
    Environment = var.environment
  })
}

resource "random_string" "suffix" {
  length  = 5
  special = false
  upper   = false
  numeric = true
}

module "resource_group" {
  source   = "./modules/resource_group"
  name     = var.resource_group_name
  location = var.location
  tags     = local.common_tags
}

module "log_analytics_workspace" {
  source              = "./modules/log_analytics_workspace"
  prefix              = var.prefix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

module "container_registry" {
  source              = "./modules/container_registry"
  prefix              = var.prefix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  name_suffix         = random_string.suffix.result
  tags                = local.common_tags
}

module "container_app_environment" {
  source                     = "./modules/container_app_environment"
  prefix                     = var.prefix
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = local.common_tags
}

module "signalr_service" {
  source              = "./modules/signalr_service"
  prefix              = var.prefix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  name_suffix         = random_string.suffix.result
  tags                = local.common_tags
}

module "api_management" {
  source              = "./modules/api_management"
  prefix              = var.prefix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  name_suffix         = random_string.suffix.result
  tags                = local.common_tags
}

module "dashboard_api" {
  source                       = "./modules/container_app"
  name                         = "dashboard-api"
  prefix                       = var.prefix
  container_name               = "dashboard-api"
  image                        = var.dashboard_api_image
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  min_replicas                 = var.dashboard_api_min_replicas
  max_replicas                 = var.dashboard_api_max_replicas
  secret_name                  = "signalr-connection"
  secret_value                 = module.signalr_service.primary_connection_string
  environment_variables = {
    SignalR__ConnectionString = "signalr-connection"
  }
  tags = local.common_tags
}

module "metrics_producer" {
  source                       = "./modules/container_app"
  name                         = "metrics-producer"
  prefix                       = var.prefix
  container_name               = "metrics-producer"
  image                        = var.metrics_producer_image
  resource_group_name          = module.resource_group.name
  container_app_environment_id = module.container_app_environment.id
  min_replicas                 = var.metrics_producer_min_replicas
  max_replicas                 = var.metrics_producer_max_replicas
  secret_name                  = "signalr-connection"
  secret_value                 = module.signalr_service.primary_connection_string
  environment_variables = {
    SignalR__ConnectionString = "signalr-connection"
  }
  tags = local.common_tags
}
