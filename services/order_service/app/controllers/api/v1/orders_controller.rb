# frozen_string_literal: true

module Api
  module V1
    class OrdersController < ApplicationController
      def index
        orders = if params[:customer_id].present?
                   Order.by_customer(params[:customer_id])
                 else
                   Order.all
                 end

        render json: OrderSerializer.new(orders).serialize
      end

      def show
        order = Order.find(params[:id])
        render json: OrderSerializer.new(order).serialize
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Order not found" }, status: :not_found
      end

      def create
        result = create_service.call(order_params)

        if result.success?
          render json: order_response(result), status: :created
        else
          render json: { errors: result.errors }, status: :unprocessable_entity
        end
      end

      private

      def order_params
        params.require(:order).permit(:customer_id, :product_name, :quantity, :price, :status).to_h.symbolize_keys
      end

      def create_service
        @create_service ||= Orders::CreateService.new
      end

      def order_response(result)
        {
          order: OrderSerializer.new(result.order).serializable_hash,
          customer: result.customer_info
        }
      end
    end
  end
end
