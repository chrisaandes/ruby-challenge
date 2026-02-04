# Event Catalog

## Overview

Events are published to RabbitMQ using a topic exchange pattern.

- **Exchange**: `orders.events`
- **Exchange Type**: topic
- **Durability**: true

## Events

### order.created

Published when a new order is successfully created.

**Routing Key**: `orders.created`

**Queue**: `customer_service.order_created`

**Schema:**
```json
{
  "event_type": "order.created",
  "event_id": "550e8400-e29b-41d4-a716-446655440000",
  "timestamp": "2025-01-15T10:30:00Z",
  "payload": {
    "order_id": 1,
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99,
    "status": "pending",
    "total_amount": 4999.98,
    "created_at": "2025-01-15T10:30:00Z"
  }
}
```

**Consumer Actions:**
- Customer Service increments `orders_count` for the associated customer

**Idempotency:**
- Events are tracked by `event_id` in `processed_events` table
- Duplicate events are acknowledged but not reprocessed

**Error Handling:**
- Invalid JSON: `reject` (no requeue)
- Customer not found: `reject` (no requeue)
- Processing error: `reject` (moves to DLQ)
