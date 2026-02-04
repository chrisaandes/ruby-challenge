# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Order Event Contract" do
  let(:connection) { Bunny.new(RABBITMQ_URL).tap(&:start) }
  let(:channel) { connection.create_channel }
  let(:queue) { channel.queue("test.order.events", auto_delete: true) }

  after do
    channel.close
    connection.close
  end

  describe "order.created event" do
    let(:exchange) { channel.topic("orders.events", passive: true) }

    before do
      queue.bind(exchange, routing_key: "orders.created")
    end

    it "event structure matches contract" do
      order_service.post("/api/v1/orders", {
                           order: {
                             customer_id: 1,
                             product_name: "Contract Test",
                             quantity: 1,
                             price: 10.00
                           }
                         })

      event = nil
      received = wait_for_condition(timeout: 5) do
        _, _, payload = queue.pop
        if payload
          event = JSON.parse(payload)
          true
        else
          false
        end
      end

      expect(received).to be(true), "No event received"

      expect(event).to have_key("event_type")
      expect(event).to have_key("event_id")
      expect(event).to have_key("timestamp")
      expect(event).to have_key("payload")

      expect(event["event_type"]).to eq("order.created")
      expect(event["event_id"]).to match(/\A[0-9a-f-]{36}\z/)

      payload = event["payload"]
      expect(payload).to have_key("order_id")
      expect(payload).to have_key("customer_id")
      expect(payload).to have_key("product_name")
      expect(payload).to have_key("quantity")
      expect(payload).to have_key("price")
      expect(payload).to have_key("status")
    end
  end
end
