output "vpc_id" {
  value = module.network.vpc_id
}

output "public_subnets" {
  value = module.network.public_subnets
}

output "api_subnets" {
  value = module.network.api_subnets
}

output "db_subnets" {
  value = module.network.db_subnets
}

output "web_security_group_id" {
  value = module.security.web_sg_id
}

output "api_security_group_id" {
  value = module.security.api_sg_id
}

output "db_security_group_id" {
  value = module.security.db_sg_id
}
