# Customer Service

Microservicio para gestión de clientes.

## Stack

- Ruby 3.3.0
- Rails 8.0 (API mode)
- PostgreSQL 16
- RabbitMQ (consumer via Sneakers)

## API Endpoints

| Method | Endpoint | Descripción |
|--------|----------|-------------|
| GET | /api/v1/customers/:id | Obtener info del cliente |
| GET | /health | Health check |
| GET | /health/rabbitmq | Estado conexión RabbitMQ |

## Modelo

```ruby
Customer
├── name: string (required)
├── email: string (required, unique)
├── address: text (required)
└── orders_count: integer (default: 0)

ProcessedEvent
├── event_id: string (unique)
└── processed_at: datetime
```

## Respuesta API

```json
{
  "customer_name": "María García",
  "address": "Calle Principal 123, CDMX",
  "orders_count": 5
}
```

Nota: No expone `id`, `email`, `created_at`, `updated_at` por seguridad.

## Eventos Consumidos

**Queue**: `customer_service.order_created`

| Evento | Acción |
|--------|--------|
| order.created | Incrementa `orders_count` del cliente |

### Idempotencia

Los eventos se rastrean en `processed_events` para evitar procesamiento duplicado.

## Setup Local

```bash
cd services/customer_service
bundle install
rails db:create db:migrate db:seed
rails server -p 3002
```

## Iniciar Consumer

```bash
bundle exec rake consumers:start
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

## Seeds

El servicio incluye 5 clientes de ejemplo:

- María García (maria@example.com)
- Carlos López (carlos@example.com)
- Ana Martínez (ana@example.com)
- Juan Hernández (juan@example.com)
- Laura Sánchez (laura@example.com)
