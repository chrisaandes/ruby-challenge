# frozen_string_literal: true

class Order < ApplicationRecord
  enum :status, { pending: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4 }

  validates :customer_id, presence: true, numericality: { only_integer: true }
  validates :product_name, presence: true
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :status, presence: true

  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }

  def total_amount
    price * quantity
  end
end
