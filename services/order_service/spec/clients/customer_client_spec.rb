# frozen_string_literal: true

require "rails_helper"

RSpec.describe CustomerClient do
  let(:client) { described_class.new }
  let(:customer_id) { 1 }

  describe "#fetch_customer" do
    context "when customer exists" do
      before do
        stub_request(:get, "http://localhost:3002/api/v1/customers/1")
          .to_return(
            status: 200,
            body: { customer_name: "Test User", address: "123 Test St", orders_count: 5 }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns customer data" do
        result = client.fetch_customer(customer_id)

        expect(result).to be_success
        expect(result.data).to include(
          "customer_name" => "Test User",
          "address" => "123 Test St",
          "orders_count" => 5
        )
      end
    end

    context "when customer does not exist" do
      before do
        stub_request(:get, "http://localhost:3002/api/v1/customers/999999")
          .to_return(
            status: 404,
            body: { error: "Customer not found" }.to_json,
            headers: { "Content-Type" => "application/json" }
          )
      end

      it "returns failure result" do
        result = client.fetch_customer(999_999)

        expect(result).to be_failure
        expect(result.error).to eq("Customer not found")
      end
    end

    context "when service is unavailable" do
      before do
        stub_request(:get, "http://localhost:3002/api/v1/customers/1").to_timeout
      end

      it "returns failure with timeout error" do
        result = client.fetch_customer(customer_id)

        expect(result).to be_failure
        expect(result.error).to include("timeout")
      end
    end

    context "when service returns 500" do
      before do
        stub_request(:get, "http://localhost:3002/api/v1/customers/1")
          .to_return(status: 500, body: "Internal Error")
      end

      it "returns failure result" do
        result = client.fetch_customer(customer_id)

        expect(result).to be_failure
      end
    end
  end
end
