# frozen_string_literal: true

class HealthController < ApplicationController
  def rabbitmq
    if RabbitMQ.connected?
      render json: { status: "ok", rabbitmq: "connected" }
    else
      render json: { status: "error", rabbitmq: "disconnected" }, status: :service_unavailable
    end
  rescue StandardError => e
    render json: { status: "error", message: e.message }, status: :service_unavailable
  end
end
