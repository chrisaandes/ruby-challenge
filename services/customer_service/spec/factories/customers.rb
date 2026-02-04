# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    name { Faker::Name.name }
    email { Faker::Internet.unique.email }
    address { Faker::Address.full_address }
    orders_count { 0 }

    trait :with_orders do
      orders_count { Faker::Number.between(from: 1, to: 10) }
    end
  end
end
