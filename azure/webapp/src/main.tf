module "common" {
  source              = "../modules/common"
  name_prefix         = var.name_prefix
  environment         = var.environment
  resource_group_name = var.resource_group_name
  location            = var.location
  common_tags         = var.common_tags
}

module "resource_group" {
  source   = "../modules/resource_group"
  name     = module.common.resource_group_name
  location = module.common.location
  tags     = module.common.default_tags
}

module "network" {
  source                = "../modules/network"
  name_prefix           = module.common.name_prefix
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  vnet_cidr             = var.vnet.cidr
  address_prefix_length = var.vnet.address_prefix_length
  az_count              = var.az_count
  subnets               = var.vnet.subnets
  tags                  = module.common.default_tags
}

module "security" {
  source              = "../modules/security"
  name_prefix         = module.common.name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_ids          = module.network.subnet_ids
  subnet_prefixes     = module.network.subnet_prefixes
  tags                = module.common.default_tags
}

module "database" {
  source                = "../modules/database"
  name_prefix           = module.common.name_prefix
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  private_dns_zone_name = var.private_dns_zone_name
  postgres              = var.postgres
  db_subnet_ids         = module.network.subnet_ids.db
  virtual_network_id    = module.network.virtual_network_id
  tags                  = module.common.default_tags
}

module "compute" {
  source              = "../modules/compute"
  name_prefix         = module.common.name_prefix
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  webapp              = var.webapp
  tags                = module.common.default_tags
}
