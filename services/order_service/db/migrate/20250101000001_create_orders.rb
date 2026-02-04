# frozen_string_literal: true

class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.integer :customer_id, null: false
      t.string :product_name, null: false
      t.integer :quantity, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :status, default: 0, null: false

      t.timestamps
    end

    add_index :orders, :customer_id
    add_index :orders, :status
    add_index :orders, :created_at
  end
end
