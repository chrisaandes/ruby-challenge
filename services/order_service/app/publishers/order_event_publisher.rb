# frozen_string_literal: true

class OrderEventPublisher
  EXCHANGE_NAME = "orders.events"

  def initialize(channel: nil)
    @channel = channel
  end

  def publish(order)
    event = OrderCreatedEvent.new(order)

    exchange.publish(
      event.to_json,
      routing_key: event.routing_key,
      persistent: true,
      content_type: "application/json",
      message_id: event.event_id,
      timestamp: Time.current.to_i
    )

    Rails.logger.info("Published order.created event: order_id=#{order.id} event_id=#{event.event_id}")
    Result.success(event_id: event.event_id)
  rescue Bunny::Exception, StandardError => e
    Rails.logger.error("Failed to publish order event: #{e.message}")
    Result.failure("Failed to publish event: #{e.message}")
  end

  private

  def channel
    @channel || RabbitMQ.channel
  end

  def exchange
    @exchange ||= channel.topic(EXCHANGE_NAME, durable: true)
  end
end
