locals {
  resource_group_name = var.resource_group_name != "" ? var.resource_group_name : "${var.name_prefix}-${var.environment}-rg"
  default_tags = merge(var.common_tags, {
    Environment = var.environment
    Project     = var.name_prefix
  })
}

output "resource_group_name" {
  value = local.resource_group_name
}

output "name_prefix" {
  value = var.name_prefix
}

output "environment" {
  value = var.environment
}

output "location" {
  value = var.location
}

output "default_tags" {
  value = local.default_tags
}
