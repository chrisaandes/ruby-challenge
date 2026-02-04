# frozen_string_literal: true

module Orders
  class CreateService
    CreateResult = Data.define(:success?, :order, :customer_info, :errors, :event_id) do
      def failure?
        !success?
      end
    end

    def initialize(customer_client: CustomerClient.new, event_publisher: OrderEventPublisher.new)
      @customer_client = customer_client
      @event_publisher = event_publisher
    end

    def call(params)
      customer_result = @customer_client.fetch_customer(params[:customer_id])
      return failure([customer_result.error]) if customer_result.failure?

      order = Order.new(params)

      if order.save
        publish_result = @event_publisher.publish(order)

        if publish_result.failure?
          Rails.logger.warn("Order created but event publishing failed: #{publish_result.error}")
        end

        success(order, customer_result.data, publish_result.data&.dig(:event_id))
      else
        failure(order.errors.full_messages)
      end
    end

    private

    def success(order, customer_info, event_id = nil)
      CreateResult.new(
        success?: true,
        order: order,
        customer_info: customer_info,
        errors: [],
        event_id: event_id
      )
    end

    def failure(errors)
      CreateResult.new(
        success?: false,
        order: nil,
        customer_info: nil,
        errors: Array(errors),
        event_id: nil
      )
    end
  end
end
