# frozen_string_literal: true

class OrderSerializer
  include Alba::Resource

  attributes :id, :customer_id, :product_name, :quantity, :status

  attribute :created_at do |order|
    order.created_at.iso8601
  end

  attribute :price do |order|
    order.price.to_f
  end

  attribute :total_amount do |order|
    order.total_amount.to_f
  end
end
