# frozen_string_literal: true

module MessagingConfig
  EXCHANGE_NAME = "orders.events"
  EXCHANGE_TYPE = :topic

  QUEUES = {
    order_created: {
      name: "customer_service.order_created",
      routing_key: "orders.created",
      durable: true
    }
  }.freeze

  def self.setup!
    channel = RabbitMQ.channel

    exchange = channel.topic(EXCHANGE_NAME, durable: true)

    QUEUES.each do |_key, config|
      queue = channel.queue(config[:name], durable: config[:durable])
      queue.bind(exchange, routing_key: config[:routing_key])
    end

    Rails.logger.info("RabbitMQ setup complete: exchange=#{EXCHANGE_NAME}")
  end
end
