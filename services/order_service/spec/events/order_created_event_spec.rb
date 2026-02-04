# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderCreatedEvent do
  let(:order) { create(:order, id: 1, customer_id: 2, product_name: "Test", quantity: 3, price: 100.0) }
  let(:event) { described_class.new(order) }

  describe "#to_h" do
    it "returns event data as hash" do
      result = event.to_h

      expect(result).to include(
        event_type: "order.created",
        event_id: be_a(String),
        timestamp: be_a(String),
        payload: hash_including(
          order_id: 1,
          customer_id: 2,
          product_name: "Test",
          quantity: 3,
          price: 100.0,
          status: "pending"
        )
      )
    end
  end

  describe "#to_json" do
    it "returns valid JSON" do
      expect { JSON.parse(event.to_json) }.not_to raise_error
    end
  end

  describe "#event_id" do
    it "generates a UUID" do
      expect(event.event_id).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\z/i)
    end
  end

  describe "#routing_key" do
    it "returns orders.created" do
      expect(event.routing_key).to eq("orders.created")
    end
  end
end
