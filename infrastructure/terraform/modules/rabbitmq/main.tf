variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "rabbitmq_password" {
  type      = string
  sensitive = true
}

variable "instance_type" {
  type    = string
  default = "mq.t3.micro"
}

locals {
  name = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "rabbitmq" {
  name        = "${local.name}-rabbitmq-sg"
  description = "Security group for Amazon MQ RabbitMQ"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 5671
    to_port     = 5671
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rabbitmq-sg"
  }
}

resource "aws_mq_broker" "main" {
  broker_name = "${local.name}-rabbitmq"

  engine_type        = "RabbitMQ"
  engine_version     = "3.13"
  host_instance_type = var.instance_type
  deployment_mode    = var.environment == "prod" ? "CLUSTER_MULTI_AZ" : "SINGLE_INSTANCE"

  security_groups = [aws_security_group.rabbitmq.id]
  subnet_ids      = var.environment == "prod" ? var.subnet_ids : [var.subnet_ids[0]]

  user {
    username = "admin"
    password = var.rabbitmq_password
  }

  logs {
    general = true
  }

  tags = {
    Name        = "${local.name}-rabbitmq"
    Environment = var.environment
  }
}

output "endpoint" {
  value = aws_mq_broker.main.instances[0].endpoints[0]
}

output "console_url" {
  value = aws_mq_broker.main.instances[0].console_url
}

output "amqp_url" {
  value     = "amqps://admin:${var.rabbitmq_password}@${replace(aws_mq_broker.main.instances[0].endpoints[0], "amqps://", "")}"
  sensitive = true
}
