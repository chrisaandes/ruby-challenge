# frozen_string_literal: true

ActiveRecord::Schema[8.0].define(version: 2025_01_01_000002) do
  enable_extension "plpgsql"

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "email", null: false
    t.text "address", null: false
    t.integer "orders_count", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_customers_on_email", unique: true
  end

  create_table "processed_events", force: :cascade do |t|
    t.string "event_id", null: false
    t.datetime "processed_at", default: -> { "CURRENT_TIMESTAMP" }, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_processed_events_on_event_id", unique: true
  end
end
