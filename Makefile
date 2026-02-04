.PHONY: help up down logs psql rabbitmq test-orders test-customers lint setup-db test-integration test console-orders console-customers

help:
	@echo "Available commands:"
	@echo "  make up               - Start all infrastructure"
	@echo "  make down             - Stop all"
	@echo "  make logs             - View logs"
	@echo "  make psql             - Connect to PostgreSQL"
	@echo "  make rabbitmq         - Open RabbitMQ management UI"
	@echo "  make setup-db         - Setup databases"
	@echo "  make test-orders      - Run order service tests"
	@echo "  make test-customers   - Run customer service tests"
	@echo "  make test-integration - Run integration tests"
	@echo "  make test             - Run all tests"
	@echo "  make lint             - Run RuboCop on all services"
	@echo "  make console-orders   - Rails console for orders"
	@echo "  make console-customers- Rails console for customers"

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

psql:
	docker compose exec postgres psql -U postgres

rabbitmq:
	@echo "Opening RabbitMQ Management UI at http://localhost:15672"
	@echo "Login: guest/guest"
	@which xdg-open > /dev/null && xdg-open http://localhost:15672 || open http://localhost:15672 2>/dev/null || echo "Please open http://localhost:15672 manually"

setup-db:
	cd services/order_service && bundle exec rails db:create db:migrate db:seed
	cd services/customer_service && bundle exec rails db:create db:migrate db:seed

test-orders:
	cd services/order_service && bundle exec rspec

test-customers:
	cd services/customer_service && bundle exec rspec

test: test-orders test-customers

test-integration:
	docker compose -f docker-compose.test.yml up --build --exit-code-from integration_tests

lint:
	cd services/order_service && bundle exec rubocop
	cd services/customer_service && bundle exec rubocop

console-orders:
	cd services/order_service && bundle exec rails console

console-customers:
	cd services/customer_service && bundle exec rails console

# Terraform commands
tf-init:
	cd infrastructure/terraform/environments/dev && terraform init

tf-plan:
	cd infrastructure/terraform/environments/dev && terraform plan

tf-apply:
	cd infrastructure/terraform/environments/dev && terraform apply

tf-destroy:
	cd infrastructure/terraform/environments/dev && terraform destroy
