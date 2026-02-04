# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderCreatedConsumer do
  let(:consumer) { described_class.new }
  let(:customer) { create(:customer, orders_count: 5) }

  let(:valid_event) do
    {
      "event_type" => "order.created",
      "event_id" => SecureRandom.uuid,
      "timestamp" => Time.current.iso8601,
      "payload" => {
        "order_id" => 1,
        "customer_id" => customer.id,
        "product_name" => "Test Product",
        "quantity" => 2,
        "price" => 99.99,
        "status" => "pending"
      }
    }
  end

  describe "#work" do
    context "with valid event" do
      it "increments customer orders_count" do
        expect {
          consumer.work(valid_event.to_json)
        }.to change { customer.reload.orders_count }.from(5).to(6)
      end

      it "returns :ack" do
        result = consumer.work(valid_event.to_json)
        expect(result).to eq(:ack)
      end

      it "logs the processing" do
        expect(Rails.logger).to receive(:info).with(/Processing order.created/)
        expect(Rails.logger).to receive(:info).with(/Successfully processed/)
        consumer.work(valid_event.to_json)
      end
    end

    context "with duplicate event (idempotency)" do
      let!(:processed_event) { ProcessedEvent.create!(event_id: valid_event["event_id"]) }

      it "does not increment orders_count" do
        expect {
          consumer.work(valid_event.to_json)
        }.not_to(change { customer.reload.orders_count })
      end

      it "returns :ack (acknowledges but skips)" do
        result = consumer.work(valid_event.to_json)
        expect(result).to eq(:ack)
      end

      it "logs skipping duplicate" do
        expect(Rails.logger).to receive(:info).with(/Skipping duplicate event/)
        consumer.work(valid_event.to_json)
      end
    end

    context "when customer does not exist" do
      let(:event_with_invalid_customer) do
        valid_event.merge("payload" => valid_event["payload"].merge("customer_id" => 999_999))
      end

      it "returns :reject" do
        result = consumer.work(event_with_invalid_customer.to_json)
        expect(result).to eq(:reject)
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Customer not found/)
        consumer.work(event_with_invalid_customer.to_json)
      end
    end

    context "with invalid JSON" do
      it "returns :reject" do
        result = consumer.work("invalid json")
        expect(result).to eq(:reject)
      end
    end

    context "with missing required fields" do
      let(:incomplete_event) do
        { "event_type" => "order.created" }.to_json
      end

      it "returns :reject" do
        result = consumer.work(incomplete_event)
        expect(result).to eq(:reject)
      end
    end
  end
end
