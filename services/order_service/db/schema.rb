# frozen_string_literal: true

ActiveRecord::Schema[8.0].define(version: 2025_01_01_000001) do
  enable_extension "plpgsql"

  create_table "orders", force: :cascade do |t|
    t.integer "customer_id", null: false
    t.string "product_name", null: false
    t.integer "quantity", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["status"], name: "index_orders_on_status"
  end
end
