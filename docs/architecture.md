# Architecture Documentation

## System Architecture

### Microservices Design

The system follows a microservices architecture with:

1. **Order Service**: Manages order lifecycle
2. **Customer Service**: Manages customer data

### Communication Patterns

#### Synchronous (HTTP)
- Order Service -> Customer Service
- Used when creating orders to fetch customer information
- Implemented with Faraday + retry middleware

#### Asynchronous (Events)
- Order Service -> RabbitMQ -> Customer Service
- Used to update `orders_count` after order creation
- Decouples services and ensures eventual consistency

### Design Decisions

#### Why Two Separate Databases?
- Database per service pattern
- Independent scaling
- Service autonomy
- No direct database coupling

#### Why RabbitMQ?
- Reliable message delivery
- Topic-based routing
- Built-in retry mechanisms
- Management UI for debugging

#### Why Service Objects?
- Single Responsibility Principle
- Testable business logic
- Clean controllers
- Dependency injection support

### Resilience Patterns

#### HTTP Client Resilience
- Retries with exponential backoff
- Timeout configuration
- Connection pooling

#### Event Processing Resilience
- Idempotent consumers
- Dead letter queues
- Event tracking table

### Scaling Considerations

#### Horizontal Scaling
- Stateless services
- Multiple consumer instances
- Load balancer ready

#### Database Scaling
- Read replicas possible
- Connection pooling
- Index optimization
