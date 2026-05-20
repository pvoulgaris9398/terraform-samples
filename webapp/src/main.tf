terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "network" {
  source   = "./modules/network"
  vpc_cidr = var.vpc_cidr
  az_count = var.az_count
}

module "security" {
  source          = "./modules/security"
  vpc_id          = module.network.vpc_id
  web_cidr_blocks = var.web_cidr_blocks
  api_port        = var.api_port
  db_port         = var.db_port
  web_sg_name     = var.web_sg_name
  api_sg_name     = var.api_sg_name
  db_sg_name      = var.db_sg_name
}
