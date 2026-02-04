# frozen_string_literal: true

FactoryBot.define do
  factory :processed_event do
    event_id { SecureRandom.uuid }
    processed_at { Time.current }
  end
end
