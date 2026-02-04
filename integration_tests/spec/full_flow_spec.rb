# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Full Order Flow Integration" do
  let(:customer_id) { 1 }

  describe "creating an order" do
    let(:order_params) do
      {
        order: {
          customer_id: customer_id,
          product_name: "Integration Test Product #{Time.now.to_i}",
          quantity: 2,
          price: 149.99
        }
      }
    end

    it "successfully creates order and updates customer orders_count" do
      initial_response = customer_service.get("/api/v1/customers/#{customer_id}")
      expect(initial_response.status).to eq(200)
      initial_orders_count = initial_response.body["orders_count"]

      create_response = order_service.post("/api/v1/orders", order_params)
      expect(create_response.status).to eq(201)

      order = create_response.body["order"]
      expect(order["customer_id"]).to eq(customer_id)
      expect(order["status"]).to eq("pending")

      expect(create_response.body["customer"]).to include("customer_name", "address")

      event_processed = wait_for_condition(timeout: 15) do
        response = customer_service.get("/api/v1/customers/#{customer_id}")
        response.body["orders_count"] > initial_orders_count
      end

      expect(event_processed).to be(true), "Event was not processed within timeout"

      final_response = customer_service.get("/api/v1/customers/#{customer_id}")
      expect(final_response.body["orders_count"]).to eq(initial_orders_count + 1)
    end
  end

  describe "listing orders by customer" do
    before do
      order_service.post("/api/v1/orders", {
                           order: {
                             customer_id: customer_id,
                             product_name: "List Test Product",
                             quantity: 1,
                             price: 50.00
                           }
                         })
    end

    it "returns orders for specific customer" do
      response = order_service.get("/api/v1/orders?customer_id=#{customer_id}")

      expect(response.status).to eq(200)
      expect(response.body).to be_an(Array)
      expect(response.body).to all(include("customer_id" => customer_id))
    end
  end

  describe "health checks" do
    it "order service is healthy" do
      response = order_service.get("/health")
      expect(response.status).to eq(200)
    end

    it "customer service is healthy" do
      response = customer_service.get("/health")
      expect(response.status).to eq(200)
    end

    it "order service rabbitmq connection is healthy" do
      response = order_service.get("/health/rabbitmq")
      expect(response.status).to eq(200)
      expect(response.body["rabbitmq"]).to eq("connected")
    end
  end
end
