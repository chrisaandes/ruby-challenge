# frozen_string_literal: true

module Api
  module V1
    class CustomersController < ApplicationController
      def show
        customer = Customer.find(params[:id])
        render json: CustomerSerializer.new(customer).serialize
      rescue ActiveRecord::RecordNotFound
        render json: { error: "Customer not found" }, status: :not_found
      end
    end
  end
end
