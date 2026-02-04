# frozen_string_literal: true

class ApplicationController < ActionController::API
  rescue_from StandardError, with: :internal_error

  private

  def internal_error(exception)
    Rails.logger.error(exception.message)
    Rails.logger.error(exception.backtrace.join("\n"))
    render json: { error: "Internal server error" }, status: :internal_server_error
  end
end
