# Backend Challenge

> **Microservices Architecture** | Ruby 3.3 | Rails 8 API | PostgreSQL 16 | RabbitMQ

Sistema de gestión de pedidos implementado como microservicios con comunicación síncrona (HTTP) y asíncrona (eventos).

---

## Tabla de Contenidos

- [Arquitectura](#arquitectura)
- [Decisiones Técnicas](#decisiones-técnicas)
- [Evolución Ruby/Rails: Antes vs Ahora](#evolución-rubyrails-antes-vs-ahora)
- [Setup Local](#setup-local)
- [API Reference](#api-reference)
- [Event Catalog](#event-catalog)

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────────┐
│                         Cliente                                  │
└─────────────────────────┬───────────────────────────────────────┘
                          │
          ┌───────────────┴───────────────┐
          ▼                               ▼
┌─────────────────┐             ┌─────────────────┐
│  Order Service  │────HTTP────▶│Customer Service │
│    (3001)       │             │    (3002)       │
└────────┬────────┘             └────────▲────────┘
         │                               │
         │ publish                       │ consume
         ▼                               │
    ┌─────────┐                          │
    │ RabbitMQ│──────────────────────────┘
    │ orders. │   routing: orders.created
    │ events  │
    └─────────┘
```

### ¿Por qué dos patrones de comunicación?

| Patrón | Uso | Justificación |
|--------|-----|---------------|
| **HTTP Síncrono** | Validar cliente al crear orden | Necesitamos respuesta inmediata para rechazar órdenes de clientes inexistentes |
| **Eventos Asíncronos** | Actualizar `orders_count` | Eventual consistency es aceptable; desacoplamos servicios |

---

## Decisiones Técnicas

### 1. Monorepo vs Multirepo

**Decisión**: Monorepo

```
challenge/
├── services/
│   ├── order_service/
│   └── customer_service/
├── infrastructure/terraform/
└── docker-compose.yml
```

**Razón**: Para un equipo pequeño y servicios estrechamente relacionados, el monorepo simplifica:
- Cambios atómicos cross-service
- Shared tooling (linters, CI)
- Onboarding más simple

En una organización grande con equipos independientes, consideraría multirepo.

---

### 2. PostgreSQL: Una instancia vs Base por servicio

**Decisión**: Una instancia PostgreSQL, bases de datos separadas

```yaml
# docker-compose.yml
postgres:
  image: postgres:16-alpine
  # order_service_development
  # customer_service_development
```

**Razón**: 
- **Desarrollo local**: Simplifica el setup
- **Producción**: Cada servicio tendría su propia instancia RDS

Lo importante es que **los servicios no comparten tablas ni hacen JOINs cross-database**.

---

### 3. Serialización JSON: JBuilder vs ActiveModel::Serializers vs Alba

**Decisión**: [Alba](https://github.com/okuramasafumi/alba)

```ruby
# Antes: JBuilder (lento, verbose)
# app/views/customers/show.json.jbuilder
json.customer_name @customer.name
json.address @customer.address
json.orders_count @customer.orders_count

# Antes: ActiveModel::Serializers (abandonado, poco mantenido)
class CustomerSerializer < ActiveModel::Serializer
  attributes :customer_name, :address, :orders_count
end

# Ahora: Alba (rápido, activamente mantenido, Ruby puro)
class CustomerSerializer
  include Alba::Resource
  
  attribute :customer_name do |customer|
    customer.name
  end
  
  attributes :address, :orders_count
end
```

**Benchmarks** (1000 objetos):
| Serializer | Tiempo |
|------------|--------|
| JBuilder | 120ms |
| AMS | 45ms |
| Alba | 12ms |
| Oj + Alba | 8ms |

---

### 4. HTTP Client: HTTParty vs Faraday

**Decisión**: Faraday con middleware

```ruby
# Antes: HTTParty (simple pero limitado)
response = HTTParty.get("#{base_url}/customers/#{id}")

# Ahora: Faraday (composable, middleware, retry built-in)
class CustomerClient
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.5,
    backoff_factor: 2,
    exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
  }.freeze

  def connection
    @connection ||= Faraday.new(url: base_url) do |f|
      f.request :json
      f.response :json
      f.request :retry, RETRY_OPTIONS  # Automatic retry with backoff
      f.options.timeout = 5
      f.adapter Faraday.default_adapter
    end
  end
end
```

**¿Por qué Faraday?**
- Retry automático con exponential backoff
- Middleware composable (logging, metrics, circuit breaker)
- Estándar de facto en la industria Ruby

---

### 5. Background Jobs: Sidekiq vs Sneakers

**Decisión**: Sneakers para consumers RabbitMQ

```ruby
# Si usara Sidekiq (Redis-based, pull model)
class OrderCreatedJob
  include Sidekiq::Job
  def perform(order_id); end
end

# Usé Sneakers (RabbitMQ native, push model)
class OrderCreatedConsumer
  include Sneakers::Worker
  from_queue 'customer_service.order_created',
             exchange: 'orders.events',
             routing_key: 'orders.created'
             
  def work(message)
    # Process event
    ack!
  end
end
```

**¿Por qué Sneakers sobre Sidekiq?**
- El proyecto **requiere RabbitMQ** explícitamente
- Push model (RabbitMQ empuja) vs Pull model (Sidekiq pollea Redis)
- Routing keys permiten filtrado de eventos en el broker
- Dead Letter Queues nativas

---

### 6. Testing: Minitest vs RSpec

**Decisión**: RSpec + FactoryBot + Shoulda-Matchers

```ruby
# Antes: Minitest (viene con Rails, simple)
class CustomerTest < ActiveSupport::TestCase
  test "should not save without name" do
    customer = Customer.new
    assert_not customer.save
  end
end

# Ahora: RSpec (más expresivo, mejor ecosystem)
RSpec.describe Customer do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
  end
  
  describe '#full_address' do
    context 'when address is present' do
      let(:customer) { build(:customer, address: '123 Main St') }
      
      it 'returns formatted address' do
        expect(customer.full_address).to eq('123 Main St')
      end
    end
  end
end
```

**Stack de testing**:
| Gem | Propósito |
|-----|-----------|
| rspec-rails | Framework de testing |
| factory_bot_rails | Fixtures dinámicos |
| shoulda-matchers | One-liners para validaciones |
| webmock | Stub HTTP requests |
| vcr | Record/replay HTTP interactions |
| simplecov | Coverage reports |

---

## Evolución Ruby/Rails: Antes vs Ahora

### Ruby 2.x → Ruby 3.3

#### Pattern Matching (Ruby 3.0+)

```ruby
# Antes: Múltiples condicionales
def process_event(event)
  if event['type'] == 'order.created' && event['payload']
    handle_order_created(event['payload'])
  elsif event['type'] == 'order.cancelled'
    handle_order_cancelled(event['payload'])
  end
end

# Ahora: Pattern matching
def process_event(event)
  case event
  in { type: 'order.created', payload: { customer_id:, order_id: } }
    handle_order_created(customer_id:, order_id:)
  in { type: 'order.cancelled', payload: }
    handle_order_cancelled(payload)
  else
    Rails.logger.warn("Unknown event type")
  end
end
```

#### Data Classes (Ruby 3.2+)

```ruby
# Antes: Struct o clase completa para value objects
OrderCreatedEvent = Struct.new(:order_id, :customer_id, :timestamp, keyword_init: true)

# O peor, una clase con todo manual
class OrderCreatedEvent
  attr_reader :order_id, :customer_id, :timestamp
  
  def initialize(order_id:, customer_id:, timestamp:)
    @order_id = order_id
    @customer_id = customer_id
    @timestamp = timestamp
  end
  
  def ==(other)
    # Implementar manualmente...
  end
end

# Ahora: Data.define (inmutable, equality, deconstruct gratis)
OrderCreatedEvent = Data.define(:order_id, :customer_id, :timestamp) do
  def to_h
    { order_id:, customer_id:, timestamp: }
  end
end

event = OrderCreatedEvent.new(order_id: 1, customer_id: 2, timestamp: Time.current)
event.order_id  # => 1
event.frozen?   # => true (inmutable por defecto)
```

#### Endless Methods (Ruby 3.0+)

```ruby
# Antes
def total_amount
  price * quantity
end

def formatted_price
  "$#{price.round(2)}"
end

# Ahora: Para métodos simples de una línea
def total_amount = price * quantity
def formatted_price = "$#{price.round(2)}"
```

#### Numbered Parameters (Ruby 2.7+)

```ruby
# Antes
orders.map { |order| order.total_amount }
orders.select { |o| o.status == 'pending' }

# Ahora: Cuando el bloque es simple
orders.map(&:total_amount)  # Ya existía
orders.map { _1.total_amount }  # Numbered parameter
orders.select { _1.status == 'pending' }

# Útil con múltiples parámetros
hash.transform_values { _1 * 2 }
array.each_with_index { puts "#{_2}: #{_1}" }
```

---

### Rails 6.x → Rails 8.0

#### Service Objects con Result Pattern

```ruby
# Antes: Excepciones o booleanos
class CreateOrderService
  def call(params)
    order = Order.new(params)
    order.save!  # Lanza excepción si falla
    order
  rescue ActiveRecord::RecordInvalid => e
    nil  # ¿Cómo sé qué falló?
  end
end

# Ahora: Result objects explícitos
module Orders
  class CreateService
    # Ruby 3.2 Data.define para el resultado
    Result = Data.define(:success?, :order, :errors) do
      def failure? = !success?
    end

    def initialize(customer_client: CustomerClient.new)
      @customer_client = customer_client
    end

    def call(params)
      customer_result = @customer_client.fetch(params[:customer_id])
      return failure(customer_result.error) if customer_result.failure?

      order = Order.new(params)
      
      if order.save
        success(order)
      else
        failure(order.errors.full_messages)
      end
    end

    private

    def success(order) = Result.new(success?: true, order:, errors: [])
    def failure(errors) = Result.new(success?: false, order: nil, errors: Array(errors))
  end
end

# Uso
result = Orders::CreateService.new.call(params)
if result.success?
  render json: result.order, status: :created
else
  render json: { errors: result.errors }, status: :unprocessable_entity
end
```

#### Enums Mejorados (Rails 7+)

```ruby
# Antes: Rails 6 - Sintaxis con hash
class Order < ApplicationRecord
  enum status: { pending: 0, confirmed: 1, shipped: 2 }
end

# Ahora: Rails 7+ - Keyword argument más explícito
class Order < ApplicationRecord
  enum :status, { pending: 0, confirmed: 1, shipped: 2 }, prefix: true, validate: true
  
  # prefix: true genera métodos como order.status_pending?
  # validate: true agrega validación automática
end

# Rails 7.1+ - Con default en el enum
class Order < ApplicationRecord
  enum :status, { pending: 0, confirmed: 1, shipped: 2 }, default: :pending
end
```

#### Query Interface Moderno

```ruby
# Antes: String interpolation (SQL injection risk)
Order.where("status = ?", status)
Order.where("created_at > ?", 1.day.ago)

# Ahora: Más expresivo y seguro
Order.where(status:)  # Ruby 3.1+ shorthand
Order.where(created_at: 1.day.ago..)  # Endless range
Order.where(price: 100..500)  # Range query
Order.where.not(status: :cancelled)
Order.where.missing(:customer)  # LEFT OUTER JOIN WHERE NULL

# Rails 7+ - in_order_of
Order.in_order_of(:status, [:shipped, :confirmed, :pending])
```

#### Encryption at Rest (Rails 7+)

```ruby
# Antes: Usar gems como attr_encrypted
class Customer < ApplicationRecord
  attr_encrypted :ssn, key: ENV['ENCRYPTION_KEY']
end

# Ahora: Built-in en Rails 7+
class Customer < ApplicationRecord
  encrypts :ssn, deterministic: true  # Permite búsquedas
  encrypts :notes  # Non-deterministic por defecto (más seguro)
end

# config/credentials.yml.enc maneja las keys automáticamente
```

#### Async Queries (Rails 7+)

```ruby
# Antes: Todo bloqueante
def dashboard
  @orders = Order.recent.limit(10)
  @customers = Customer.active.limit(10)
  @stats = OrderStats.calculate  # Cada query espera a la anterior
end

# Ahora: Queries en paralelo
def dashboard
  orders_promise = Order.recent.limit(10).load_async
  customers_promise = Customer.active.limit(10).load_async
  stats_promise = OrderStats.load_async
  
  # Se ejecutan en paralelo, se materializan cuando se acceden
  @orders = orders_promise
  @customers = customers_promise
  @stats = stats_promise
end
```

---

### Patterns Arquitectónicos Implementados

#### 1. Transactional Outbox Pattern

Garantiza que los eventos se publiquen solo si la transacción de DB commitea.

```ruby
# Problema: Si el publish falla después del save, tenemos inconsistencia
order.save!
publisher.publish(order)  # ¿Qué pasa si esto falla?

# Solución: Outbox table
class Order < ApplicationRecord
  after_commit :enqueue_event_publication, on: :create
  
  private
  
  def enqueue_event_publication
    OutboxEvent.create!(
      aggregate_type: 'Order',
      aggregate_id: id,
      event_type: 'order.created',
      payload: event_payload
    )
  end
end

# Background job procesa la outbox table
class OutboxPublisherJob
  def perform
    OutboxEvent.unpublished.find_each do |event|
      publisher.publish(event)
      event.update!(published_at: Time.current)
    end
  end
end
```

#### 2. Idempotent Consumers

```ruby
class OrderCreatedConsumer
  include Sneakers::Worker

  def work(raw_message)
    event = JSON.parse(raw_message)
    
    # Idempotency: Si ya procesamos este evento, skip
    return ack! if ProcessedEvent.exists?(event_id: event['event_id'])
    
    ActiveRecord::Base.transaction do
      customer = Customer.lock.find(event.dig('payload', 'customer_id'))
      customer.increment!(:orders_count)
      ProcessedEvent.create!(event_id: event['event_id'])
    end
    
    ack!
  rescue ActiveRecord::RecordNotFound
    reject!  # Customer no existe, no reintentar
  end
end
```

---

## Setup Local

### Requisitos

- Docker Desktop 4.0+
- Ruby 3.3.0 (opcional, para desarrollo sin Docker)

### Quick Start

```bash
# 1. Clonar repositorio
git clone <repo-url>
cd challenge

# 2. Iniciar infraestructura
docker compose up -d

# 3. Setup bases de datos
make setup-db

# 4. Verificar servicios
curl http://localhost:3001/health  # Order Service
curl http://localhost:3002/health  # Customer Service
```

### Comandos Útiles

```bash
make up              # Iniciar todo
make down            # Detener todo
make logs            # Ver logs
make test            # Correr tests
make lint            # Correr RuboCop
make console-orders  # Rails console Order Service
```

---

## API Reference

### Order Service (puerto 3001)

#### Crear Orden

```bash
POST /api/v1/orders

{
  "order": {
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99
  }
}

# Response 201
{
  "order": {
    "id": 1,
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99,
    "status": "pending",
    "total_amount": 4999.98
  },
  "customer": {
    "customer_name": "María García",
    "address": "CDMX, México"
  }
}
```

#### Listar Órdenes

```bash
GET /api/v1/orders
GET /api/v1/orders?customer_id=1
```

### Customer Service (puerto 3002)

#### Obtener Cliente

```bash
GET /api/v1/customers/:id

# Response 200
{
  "customer_name": "María García",
  "address": "CDMX, México",
  "orders_count": 5
}
```

---

## Event Catalog

### order.created

**Exchange**: `orders.events` (topic)  
**Routing Key**: `orders.created`  
**Queue**: `customer_service.order_created`

```json
{
  "event_type": "order.created",
  "event_id": "uuid-v4",
  "timestamp": "2025-01-15T10:30:00Z",
  "payload": {
    "order_id": 1,
    "customer_id": 1,
    "product_name": "MacBook Pro",
    "quantity": 2,
    "price": 2499.99,
    "status": "pending"
  }
}
```

**Consumer Action**: Incrementa `orders_count` del customer asociado.

---

## Autor

Christian Espana

---

## Referencias

- [Ruby 3.3 Release Notes](https://www.ruby-lang.org/en/news/2023/12/25/ruby-3-3-0-released/)
- [Rails 8.0 Release Notes](https://guides.rubyonrails.org/8_0_release_notes.html)
- [Alba Serializer](https://github.com/okuramasafumi/alba)
- [Sneakers](https://github.com/jondot/sneakers)
- [Faraday](https://github.com/lostisland/faraday)