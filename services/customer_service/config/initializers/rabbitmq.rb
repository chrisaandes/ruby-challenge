# frozen_string_literal: true

require "bunny"

module RabbitMQ
  class << self
    def connection
      @connection ||= begin
        conn = Bunny.new(connection_url)
        conn.start
        conn
      end
    end

    def channel
      @channel ||= connection.create_channel
    end

    def close
      @channel&.close
      @connection&.close
      @channel = nil
      @connection = nil
    end

    def connection_url
      ENV.fetch("RABBITMQ_URL", "amqp://guest:guest@localhost:5672")
    end

    def connected?
      @connection&.open? && @channel&.open?
    end
  end
end

at_exit { RabbitMQ.close }
