# frozen_string_literal: true

require "faraday"
require "bunny"
require "json"

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.order = :random
end

ORDER_SERVICE_URL = ENV.fetch("ORDER_SERVICE_URL", "http://localhost:3001")
CUSTOMER_SERVICE_URL = ENV.fetch("CUSTOMER_SERVICE_URL", "http://localhost:3002")
RABBITMQ_URL = ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672")

def order_service
  @order_service ||= Faraday.new(url: ORDER_SERVICE_URL) do |f|
    f.request :json
    f.response :json
    f.adapter Faraday.default_adapter
  end
end

def customer_service
  @customer_service ||= Faraday.new(url: CUSTOMER_SERVICE_URL) do |f|
    f.request :json
    f.response :json
    f.adapter Faraday.default_adapter
  end
end

def wait_for_condition(timeout: 10, interval: 0.5)
  deadline = Time.now + timeout

  while Time.now < deadline
    return true if yield

    sleep interval
  end

  false
end
