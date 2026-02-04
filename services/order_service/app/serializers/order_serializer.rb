# frozen_string_literal: true

class OrderSerializer
  include Alba::Resource

  attributes :id, :customer_id, :product_name, :quantity, :status, :created_at

  attribute :price do |order|
    order.price.to_f
  end

  attribute :total_amount do |order|
    order.total_amount.to_f
  end
end
