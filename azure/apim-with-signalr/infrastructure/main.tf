locals {
  # Generate deterministic hash suffix from workload and environment for unique naming
  # This ensures the same suffix is used across all resources in the same deployment
  name_suffix = substr(md5("${var.workload}-${var.environment}"), 0, 5)

  # Recommended tagging for Azure resources
  common_tags = merge(var.tags, {
    Environment = var.environment
    Workload    = var.workload
    Owner       = var.owner
    CostCenter  = var.cost_center
    ManagedBy   = "Terraform"
    CreatedDate = formatdate("YYYY-MM-DD", timestamp())
  })
}

module "resource_group" {
  source      = "./modules/resource_group"
  workload    = var.workload
  environment = var.environment
  name_suffix = local.name_suffix
  location    = var.location
  tags        = local.common_tags
}

module "log_analytics_workspace" {
  source              = "./modules/log_analytics_workspace"
  workload            = var.workload
  environment         = var.environment
  name_suffix         = local.name_suffix
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  tags                = local.common_tags
}

module "container_registry" {
  source              = "./modules/container_registry"
  workload            = var.workload
  environment         = var.environment
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  name_suffix         = local.name_suffix
  tags                = local.common_tags
}

module "container_app_environment" {
  source                     = "./modules/container_app_environment"
  workload                   = var.workload
  environment                = var.environment
  name_suffix                = local.name_suffix
  location                   = module.resource_group.location
  resource_group_name        = module.resource_group.name
  log_analytics_workspace_id = module.log_analytics_workspace.id
  tags                       = local.common_tags
}

module "signalr_service" {
  source              = "./modules/signalr_service"
  workload            = var.workload
  environment         = var.environment
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  name_suffix         = local.name_suffix
  tags                = local.common_tags
}

module "api_management" {
  source              = "./modules/api_management"
  workload            = var.workload
  environment         = var.environment
  location            = module.resource_group.location
  resource_group_name = module.resource_group.name
  publisher_name      = var.publisher_name
  publisher_email     = var.publisher_email
  name_suffix         = local.name_suffix
  tags                = local.common_tags
}

module "dashboard_api" {
  source                       = "./modules/container_app"
  name                         = "dashboard-api"
  workload                     = var.workload
  environment                  = var.environment
  name_suffix                  = local.name_suffix
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
  workload                     = var.workload
  environment                  = var.environment
  name_suffix                  = local.name_suffix
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
