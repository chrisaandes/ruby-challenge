# frozen_string_literal: true

class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.text :address, null: false
      t.integer :orders_count, null: false, default: 0

      t.timestamps
    end

    add_index :customers, :email, unique: true
  end
end
