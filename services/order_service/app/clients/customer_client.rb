# frozen_string_literal: true

class CustomerClient
  DEFAULT_TIMEOUT = 5
  RETRY_OPTIONS = {
    max: 3,
    interval: 0.5,
    interval_randomness: 0.5,
    backoff_factor: 2,
    exceptions: [Faraday::TimeoutError, Faraday::ConnectionFailed]
  }.freeze

  def initialize(base_url: nil, timeout: DEFAULT_TIMEOUT)
    @base_url = base_url || ENV.fetch("CUSTOMER_SERVICE_URL", "http://localhost:3002")
    @timeout = timeout
  end

  def fetch_customer(customer_id)
    response = connection.get("/api/v1/customers/#{customer_id}")

    if response.success?
      Result.success(response.body)
    else
      Result.failure(response.body["error"] || "Unknown error")
    end
  rescue Faraday::TimeoutError => e
    Rails.logger.error("CustomerClient timeout: #{e.message}")
    Result.failure("Connection timeout - customer service unavailable")
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error("CustomerClient connection failed: #{e.message}")
    Result.failure("Connection failed - customer service unavailable")
  rescue StandardError => e
    Rails.logger.error("CustomerClient error: #{e.message}")
    Result.failure("Unexpected error: #{e.message}")
  end

  private

  def connection
    @connection ||= Faraday.new(url: @base_url) do |f|
      f.request :json
      f.response :json
      f.request :retry, RETRY_OPTIONS
      f.options.timeout = @timeout
      f.options.open_timeout = @timeout
      f.adapter Faraday.default_adapter
    end
  end
end
