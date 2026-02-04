# frozen_string_literal: true

class CreateProcessedEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :processed_events do |t|
      t.string :event_id, null: false
      t.datetime :processed_at, null: false, default: -> { "CURRENT_TIMESTAMP" }

      t.timestamps
    end

    add_index :processed_events, :event_id, unique: true
  end
end
