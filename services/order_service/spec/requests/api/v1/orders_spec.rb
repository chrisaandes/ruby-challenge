# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Orders" do
  let(:customer_data) { { "customer_name" => "Test User", "address" => "123 Test St", "orders_count" => 0 } }
  let(:customer_client) { instance_double(CustomerClient) }
  let(:event_publisher) { instance_double(OrderEventPublisher) }

  before do
    allow(CustomerClient).to receive(:new).and_return(customer_client)
    allow(OrderEventPublisher).to receive(:new).and_return(event_publisher)
  end

  describe "POST /api/v1/orders" do
    let(:valid_params) do
      {
        order: {
          customer_id: 1,
          product_name: "MacBook Pro",
          quantity: 2,
          price: 2499.99
        }
      }
    end

    context "with valid parameters" do
      before do
        allow(customer_client).to receive(:fetch_customer).and_return(Result.success(customer_data))
        allow(event_publisher).to receive(:publish).and_return(Result.success(event_id: "uuid-123"))
      end

      it "returns http created" do
        post api_v1_orders_path, params: valid_params
        expect(response).to have_http_status(:created)
      end

      it "creates a new order" do
        expect {
          post api_v1_orders_path, params: valid_params
        }.to change(Order, :count).by(1)
      end

      it "returns the created order" do
        post api_v1_orders_path, params: valid_params

        json = response.parsed_body
        expect(json["order"]).to include(
          "product_name" => "MacBook Pro",
          "quantity" => 2,
          "status" => "pending"
        )
      end

      it "sets default status to pending" do
        post api_v1_orders_path, params: valid_params
        expect(Order.last.status).to eq("pending")
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) { { order: { product_name: "" } } }

      before do
        allow(customer_client).to receive(:fetch_customer).and_return(Result.success(customer_data))
      end

      it "returns http unprocessable entity" do
        post api_v1_orders_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns validation errors" do
        post api_v1_orders_path, params: invalid_params

        json = response.parsed_body
        expect(json["errors"]).to be_present
      end

      it "does not create an order" do
        expect {
          post api_v1_orders_path, params: invalid_params
        }.not_to change(Order, :count)
      end
    end

    context "when customer does not exist" do
      before do
        allow(customer_client).to receive(:fetch_customer).and_return(Result.failure("Customer not found"))
      end

      it "returns http unprocessable entity" do
        post api_v1_orders_path, params: valid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "returns error message" do
        post api_v1_orders_path, params: valid_params

        json = response.parsed_body
        expect(json["errors"]).to include("Customer not found")
      end
    end
  end

  describe "GET /api/v1/orders" do
    context "without customer_id filter" do
      let!(:orders) { create_list(:order, 3) }

      it "returns http success" do
        get api_v1_orders_path
        expect(response).to have_http_status(:ok)
      end

      it "returns all orders" do
        get api_v1_orders_path
        expect(response.parsed_body.size).to eq(3)
      end
    end

    context "with customer_id filter" do
      let!(:customer_orders) { create_list(:order, 2, customer_id: 1) }
      let!(:other_orders) { create_list(:order, 3, customer_id: 2) }

      it "returns only orders for the specified customer" do
        get api_v1_orders_path, params: { customer_id: 1 }
        expect(response.parsed_body.size).to eq(2)
      end
    end
  end

  describe "GET /api/v1/orders/:id" do
    context "when order exists" do
      let!(:order) { create(:order) }

      it "returns http success" do
        get api_v1_order_path(order)
        expect(response).to have_http_status(:ok)
      end

      it "returns the order" do
        get api_v1_order_path(order)

        json = response.parsed_body
        expect(json["id"]).to eq(order.id)
      end
    end

    context "when order does not exist" do
      it "returns http not found" do
        get api_v1_order_path(id: 999_999)
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
