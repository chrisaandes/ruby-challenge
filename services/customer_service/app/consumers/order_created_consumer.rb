# frozen_string_literal: true

class OrderCreatedConsumer
  include Sneakers::Worker

  from_queue "customer_service.order_created",
             exchange: "orders.events",
             exchange_type: :topic,
             routing_key: "orders.created",
             durable: true

  def work(raw_message)
    event = parse_event(raw_message)
    return :reject unless event

    if already_processed?(event["event_id"])
      Rails.logger.info("Skipping duplicate event: #{event["event_id"]}")
      return :ack
    end

    process_event(event)
  rescue StandardError => e
    Rails.logger.error("Error processing event: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    :reject
  end

  private

  def parse_event(raw_message)
    event = JSON.parse(raw_message)

    unless valid_event?(event)
      Rails.logger.error("Invalid event structure: #{raw_message}")
      return nil
    end

    event
  rescue JSON::ParserError => e
    Rails.logger.error("Failed to parse event: #{e.message}")
    nil
  end

  def valid_event?(event)
    event["event_type"] == "order.created" &&
      event["event_id"].present? &&
      event.dig("payload", "customer_id").present?
  end

  def already_processed?(event_id)
    ProcessedEvent.exists?(event_id: event_id)
  end

  def process_event(event)
    customer_id = event.dig("payload", "customer_id")
    event_id = event["event_id"]

    Rails.logger.info("Processing order.created event: #{event_id} for customer: #{customer_id}")

    ActiveRecord::Base.transaction do
      customer = Customer.lock.find(customer_id)
      customer.increment!(:orders_count)
      ProcessedEvent.create!(event_id: event_id)
    end

    Rails.logger.info("Successfully processed event: #{event_id}")
    :ack
  rescue ActiveRecord::RecordNotFound
    Rails.logger.error("Customer not found: #{customer_id}")
    :reject
  end
end
