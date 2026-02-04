# frozen_string_literal: true

require "sneakers"

Sneakers.configure(
  connection: Bunny.new(ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672")),
  exchange: "orders.events",
  exchange_type: :topic,
  durable: true,
  ack: true,
  prefetch: 10,
  threads: 2,
  timeout_job_after: 60,
  retry_timeout: 5000,
  workers: 1,
  log: Rails.logger
)

Sneakers.logger = Rails.logger
Sneakers.logger.level = Logger::INFO
