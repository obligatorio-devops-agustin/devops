provider "aws" {
  region = var.aws_region
}

module "vpc" {
  source               = "../modules/vpc"
  environment          = var.environment
  vpc_cidr             = var.vpc_cidr
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
}

module "ecs" {
  source                = "../modules/ecs"
  environment           = var.environment
  services              = var.services
  dockerhub_username    = var.dockerhub_username
  github_sha            = var.github_sha
  subnets               = module.vpc.private_subnets
  ecs_alb_dns           = module.alb.alb_dns_name
  vpc_id                = module.vpc.vpc_id 
  alb_security_group_id = module.alb.alb_security_group_id
  private_subnets       = module.vpc.private_subnets 
  ecs_tg_arn            = module.alb.ecs_tg_arn
}

module "alb" {
  source         = "../modules/alb"
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  public_subnets = module.vpc.public_subnets
  services       = var.services
}

module "api_gateway" {
  source           = "../modules/api_gateway"
  api_gateway_name = var.api_gateway_name
  environment      = var.environment
  api_routes       = var.api_routes
  ecs_alb_dns      = module.alb.alb_dns_name
}