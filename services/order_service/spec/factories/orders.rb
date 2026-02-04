# frozen_string_literal: true

FactoryBot.define do
  factory :order do
    customer_id { Faker::Number.between(from: 1, to: 100) }
    product_name { Faker::Commerce.product_name }
    quantity { Faker::Number.between(from: 1, to: 10) }
    price { Faker::Commerce.price(range: 10.0..1000.0) }
    status { :pending }

    trait :confirmed do
      status { :confirmed }
    end

    trait :shipped do
      status { :shipped }
    end

    trait :delivered do
      status { :delivered }
    end

    trait :cancelled do
      status { :cancelled }
    end
  end
end
