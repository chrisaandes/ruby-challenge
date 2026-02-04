# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Customers" do
  describe "GET /api/v1/customers/:id" do
    context "when customer exists" do
      let!(:customer) { create(:customer, name: "Test User", address: "123 Test St", orders_count: 5) }

      it "returns http success" do
        get api_v1_customer_path(customer)
        expect(response).to have_http_status(:ok)
      end

      it "returns customer info with correct structure" do
        get api_v1_customer_path(customer)

        json = response.parsed_body
        expect(json).to include(
          "customer_name" => "Test User",
          "address" => "123 Test St",
          "orders_count" => 5
        )
      end

      it "does not include sensitive fields" do
        get api_v1_customer_path(customer)

        json = response.parsed_body
        expect(json).not_to include("email", "id", "created_at", "updated_at")
      end
    end

    context "when customer does not exist" do
      it "returns http not found" do
        get api_v1_customer_path(id: 999_999)
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        get api_v1_customer_path(id: 999_999)

        json = response.parsed_body
        expect(json).to include("error" => "Customer not found")
      end
    end
  end
end
