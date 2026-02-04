# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Customer API Contract" do
  describe "GET /api/v1/customers/:id" do
    context "when customer exists" do
      let(:response) { customer_service.get("/api/v1/customers/1") }

      it "returns 200" do
        expect(response.status).to eq(200)
      end

      it "returns required fields" do
        body = response.body

        expect(body).to have_key("customer_name")
        expect(body).to have_key("address")
        expect(body).to have_key("orders_count")
      end

      it "returns correct types" do
        body = response.body

        expect(body["customer_name"]).to be_a(String)
        expect(body["address"]).to be_a(String)
        expect(body["orders_count"]).to be_a(Integer)
      end

      it "does not expose internal fields" do
        body = response.body

        expect(body).not_to have_key("id")
        expect(body).not_to have_key("email")
        expect(body).not_to have_key("created_at")
      end
    end

    context "when customer does not exist" do
      let(:response) { customer_service.get("/api/v1/customers/999999") }

      it "returns 404" do
        expect(response.status).to eq(404)
      end

      it "returns error message" do
        expect(response.body).to have_key("error")
      end
    end
  end
end
