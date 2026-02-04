# API Documentation

## Order Service API

Base URL: `http://localhost:3001`

### Create Order

`POST /api/v1/orders`

**Request Body:**
```json
{
  "order": {
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99
  }
}
```

**Success Response (201):**
```json
{
  "order": {
    "id": 1,
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99,
    "status": "pending",
    "total_amount": 4999.98,
    "created_at": "2025-01-15T10:30:00Z"
  },
  "customer": {
    "customer_name": "Maria Garcia",
    "address": "Calle Principal 123, CDMX",
    "orders_count": 5
  }
}
```

**Error Response (422):**
```json
{
  "errors": ["Quantity must be greater than 0"]
}
```

### List Orders

`GET /api/v1/orders`

**Query Parameters:**
- `customer_id` (optional): Filter by customer

**Response (200):**
```json
[
  {
    "id": 1,
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99,
    "status": "pending",
    "total_amount": 4999.98,
    "created_at": "2025-01-15T10:30:00Z"
  }
]
```

### Get Order

`GET /api/v1/orders/:id`

**Response (200):**
```json
{
  "id": 1,
  "customer_id": 1,
  "product_name": "MacBook Pro",
  "quantity": 2,
  "price": 2499.99,
  "status": "pending",
  "total_amount": 4999.98,
  "created_at": "2025-01-15T10:30:00Z"
}
```

**Error Response (404):**
```json
{
  "error": "Order not found"
}
```

---

## Customer Service API

Base URL: `http://localhost:3002`

### Get Customer

`GET /api/v1/customers/:id`

**Response (200):**
```json
{
  "customer_name": "Maria Garcia",
  "address": "Calle Principal 123, CDMX",
  "orders_count": 5
}
```

**Error Response (404):**
```json
{
  "error": "Customer not found"
}
```
