# frozen_string_literal: true

require "rails_helper"

RSpec.describe OrderEventPublisher do
  let(:publisher) { described_class.new }
  let(:order) { create(:order) }
  let(:channel) { instance_double(Bunny::Channel) }
  let(:exchange) { instance_double(Bunny::Exchange) }

  before do
    allow(RabbitMQ).to receive(:channel).and_return(channel)
    allow(channel).to receive(:topic).and_return(exchange)
  end

  describe "#publish" do
    it "publishes event to the exchange" do
      expect(exchange).to receive(:publish) do |message, options|
        parsed = JSON.parse(message)
        expect(parsed["event_type"]).to eq("order.created")
        expect(parsed["payload"]["order_id"]).to eq(order.id)
        expect(options[:routing_key]).to eq("orders.created")
        expect(options[:persistent]).to be true
      end

      publisher.publish(order)
    end

    it "returns success result" do
      allow(exchange).to receive(:publish)

      result = publisher.publish(order)

      expect(result).to be_success
    end

    context "when RabbitMQ is unavailable" do
      before do
        allow(exchange).to receive(:publish).and_raise(Bunny::ConnectionClosedError.new(nil))
      end

      it "returns failure result" do
        result = publisher.publish(order)

        expect(result).to be_failure
        expect(result.error).to include("Failed to publish")
      end

      it "logs the error" do
        expect(Rails.logger).to receive(:error).with(/Failed to publish order event/)
        publisher.publish(order)
      end
    end
  end
end
