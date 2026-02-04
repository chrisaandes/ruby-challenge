# Troubleshooting Guide

## Common Issues

### Services Won't Start

**Symptom**: Docker containers exit immediately

**Solution**:
1. Check logs: `docker compose logs <service>`
2. Verify database is ready
3. Check environment variables

### Database Connection Failed

**Symptom**: `PG::ConnectionBad`

**Solution**:
1. Verify PostgreSQL is running: `docker compose ps postgres`
2. Check DATABASE_URL in .env
3. Ensure database exists: `make setup-db`

### RabbitMQ Connection Issues

**Symptom**: `Bunny::TCPConnectionFailed`

**Solution**:
1. Check RabbitMQ is running: `docker compose ps rabbitmq`
2. Verify RABBITMQ_URL in .env
3. Wait for RabbitMQ to fully start (~30s)

### Events Not Being Processed

**Symptom**: `orders_count` not updating

**Solution**:
1. Check consumer is running: `make logs-customer-worker`
2. Verify queue exists: http://localhost:15672
3. Check for messages in DLQ
4. Verify event format matches schema

### Customer Service Unavailable

**Symptom**: Order creation fails with "Connection timeout"

**Solution**:
1. Verify Customer Service is running
2. Check CUSTOMER_SERVICE_URL environment variable
3. Review network connectivity between containers

## Debug Commands

```bash
# Check all service health
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3001/health/rabbitmq

# Access Rails console
docker compose exec order_service rails c
docker compose exec customer_service rails c

# Access PostgreSQL
docker compose exec postgres psql -U postgres

# View RabbitMQ queues
open http://localhost:15672
```
