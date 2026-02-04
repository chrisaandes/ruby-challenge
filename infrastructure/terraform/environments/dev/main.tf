terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket = "monokera-terraform-state"
    key    = "dev/terraform.tfstate"
    region = "us-east-1"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}

variable "project_name" {
  default = "monokera"
}

variable "environment" {
  default = "dev"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "db_password" {
  sensitive = true
}

variable "rabbitmq_password" {
  sensitive = true
}

module "vpc" {
  source = "../../modules/vpc"

  project_name = var.project_name
  environment  = var.environment
}

module "rds" {
  source = "../../modules/rds"

  project_name   = var.project_name
  environment    = var.environment
  vpc_id         = module.vpc.vpc_id
  subnet_ids     = module.vpc.private_subnet_ids
  db_password    = var.db_password
  instance_class = "db.t3.micro"
}

module "rabbitmq" {
  source = "../../modules/rabbitmq"

  project_name      = var.project_name
  environment       = var.environment
  vpc_id            = module.vpc.vpc_id
  subnet_ids        = module.vpc.private_subnet_ids
  rabbitmq_password = var.rabbitmq_password
  instance_type     = "mq.t3.micro"
}

module "ecs" {
  source = "../../modules/ecs"

  project_name       = var.project_name
  environment        = var.environment
  vpc_id             = module.vpc.vpc_id
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  database_url       = module.rds.database_url
  rabbitmq_url       = module.rabbitmq.amqp_url
}

output "alb_dns_name" {
  value = module.ecs.alb_dns_name
}

output "order_service_ecr_url" {
  value = module.ecs.order_service_ecr_url
}

output "customer_service_ecr_url" {
  value = module.ecs.customer_service_ecr_url
}
