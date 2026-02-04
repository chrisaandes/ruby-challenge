# Order Service

Microservicio para gestión de órdenes.

## Stack

- Ruby 3.3.0
- Rails 8.0 (API mode)
- PostgreSQL 16
- RabbitMQ (publisher)

## API Endpoints

| Method | Endpoint | Descripción |
|--------|----------|-------------|
| POST | /api/v1/orders | Crear orden |
| GET | /api/v1/orders | Listar órdenes |
| GET | /api/v1/orders?customer_id=X | Filtrar por cliente |
| GET | /api/v1/orders/:id | Obtener orden |
| GET | /health | Health check |
| GET | /health/rabbitmq | Estado conexión RabbitMQ |

## Modelo

```ruby
Order
├── customer_id: integer (required)
├── product_name: string (required)
├── quantity: integer (> 0)
├── price: decimal (> 0)
└── status: enum (pending, confirmed, shipped, delivered, cancelled)
```

## Integración con Customer Service

Al crear una orden, se valida que el cliente exista via HTTP:

```
POST /orders → GET customer_service/api/v1/customers/:id
```

## Eventos Publicados

**Exchange**: `orders.events` (topic)

| Evento | Routing Key | Trigger |
|--------|-------------|---------|
| order.created | orders.created | Después de crear orden |

## Setup Local

```bash
cd services/order_service
bundle install
rails db:create db:migrate
rails server -p 3001
```

## Tests

```bash
bundle exec rspec
```

## Variables de Entorno

| Variable | Descripción | Default |
|----------|-------------|---------|
| DATABASE_URL | PostgreSQL connection | - |
| RABBITMQ_URL | RabbitMQ connection | amqp://guest:guest@localhost:5672 |
| CUSTOMER_SERVICE_URL | URL del Customer Service | http://localhost:3002 |
