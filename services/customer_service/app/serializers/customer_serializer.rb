# frozen_string_literal: true

class CustomerSerializer
  include Alba::Resource

  attribute :customer_name do |customer|
    customer.name
  end

  attributes :address, :orders_count
end
