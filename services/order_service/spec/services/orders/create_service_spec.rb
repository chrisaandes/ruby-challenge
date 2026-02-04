# frozen_string_literal: true

require "rails_helper"

RSpec.describe Orders::CreateService do
  let(:customer_client) { instance_double(CustomerClient) }
  let(:event_publisher) { instance_double(OrderEventPublisher) }
  let(:service) { described_class.new(customer_client: customer_client, event_publisher: event_publisher) }

  let(:valid_params) do
    {
      customer_id: 1,
      product_name: "MacBook Pro",
      quantity: 2,
      price: 2499.99
    }
  end

  let(:customer_data) do
    { "customer_name" => "John Doe", "address" => "123 Main St", "orders_count" => 5 }
  end

  describe "#call" do
    context "when customer exists and order is valid" do
      before do
        allow(customer_client).to receive(:fetch_customer)
          .with(1)
          .and_return(Result.success(customer_data))
        allow(event_publisher).to receive(:publish)
          .and_return(Result.success(event_id: "uuid-123"))
      end

      it "creates the order" do
        result = service.call(valid_params)

        expect(result).to be_success
        expect(result.order).to be_persisted
      end

      it "includes customer info in the result" do
        result = service.call(valid_params)

        expect(result.customer_info).to eq(customer_data)
      end

      it "includes event_id in result" do
        result = service.call(valid_params)
        expect(result.event_id).to eq("uuid-123")
      end
    end

    context "when customer does not exist" do
      before do
        allow(customer_client).to receive(:fetch_customer)
          .with(1)
          .and_return(Result.failure("Customer not found"))
      end

      it "returns failure" do
        result = service.call(valid_params)

        expect(result).to be_failure
        expect(result.errors).to include("Customer not found")
      end

      it "does not create an order" do
        expect { service.call(valid_params) }.not_to change(Order, :count)
      end
    end

    context "when customer service is unavailable" do
      before do
        allow(customer_client).to receive(:fetch_customer)
          .and_return(Result.failure("Connection timeout"))
      end

      it "returns failure" do
        result = service.call(valid_params)

        expect(result).to be_failure
        expect(result.errors).to include(/Connection timeout/)
      end
    end

    context "when order params are invalid" do
      let(:invalid_params) { valid_params.merge(quantity: -1) }

      before do
        allow(customer_client).to receive(:fetch_customer)
          .and_return(Result.success(customer_data))
      end

      it "returns failure with validation errors" do
        result = service.call(invalid_params)

        expect(result).to be_failure
        expect(result.errors).to include(/Quantity/)
      end
    end

    context "when event publishing fails" do
      before do
        allow(customer_client).to receive(:fetch_customer)
          .and_return(Result.success(customer_data))
        allow(event_publisher).to receive(:publish)
          .and_return(Result.failure("Connection error"))
      end

      it "still creates the order" do
        result = service.call(valid_params)
        expect(result).to be_success
        expect(result.order).to be_persisted
      end

      it "logs a warning" do
        expect(Rails.logger).to receive(:warn).with(/event publishing failed/)
        service.call(valid_params)
      end
    end
  end
end
