# frozen_string_literal: true

class OrderCreatedEvent
  attr_reader :order, :event_id, :timestamp

  ROUTING_KEY = "orders.created"

  def initialize(order)
    @order = order
    @event_id = SecureRandom.uuid
    @timestamp = Time.current.iso8601
  end

  def to_h
    {
      event_type: "order.created",
      event_id: event_id,
      timestamp: timestamp,
      payload: payload
    }
  end

  def to_json(*_args)
    to_h.to_json
  end

  def routing_key
    ROUTING_KEY
  end

  private

  def payload
    {
      order_id: order.id,
      customer_id: order.customer_id,
      product_name: order.product_name,
      quantity: order.quantity,
      price: order.price.to_f,
      status: order.status,
      total_amount: order.total_amount.to_f,
      created_at: order.created_at.iso8601
    }
  end
end
