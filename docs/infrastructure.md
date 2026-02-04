# Infrastructure Documentation

## Local Development

### Docker Compose Setup

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop all
docker compose down
```

### Services

| Service | Port | Description |
|---------|------|-------------|
| PostgreSQL | 5432 | Database server |
| RabbitMQ | 5672 | AMQP broker |
| RabbitMQ Management | 15672 | Web UI (guest/guest) |
| Order Service | 3001 | Order API |
| Customer Service | 3002 | Customer API |

## AWS Deployment

### Prerequisites

- AWS CLI configured
- Terraform 1.6+
- S3 bucket for state

### Deployment Steps

1. Initialize Terraform:
```bash
cd infrastructure/terraform/environments/dev
terraform init
```

2. Create `terraform.tfvars`:
```hcl
db_password       = "secure_password"
rabbitmq_password = "secure_password"
```

3. Plan deployment:
```bash
terraform plan
```

4. Apply:
```bash
terraform apply
```

### Resources Created

- VPC with public/private subnets
- RDS PostgreSQL instance
- Amazon MQ (RabbitMQ) broker
- ECS Cluster with Fargate
- Application Load Balancer
- ECR repositories

### Cost Estimation (Dev Environment)

| Resource | Instance | Monthly Cost |
|----------|----------|--------------|
| RDS | db.t3.micro | ~$15 |
| Amazon MQ | mq.t3.micro | ~$25 |
| ECS Fargate | 0.25 vCPU | ~$10 |
| ALB | - | ~$20 |
| **Total** | | **~$70/month** |
