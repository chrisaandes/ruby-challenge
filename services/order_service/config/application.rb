# frozen_string_literal: true

require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_view/railtie"

Bundler.require(*Rails.groups)

module OrderService
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])
    config.api_only = true
    config.eager_load_paths << Rails.root.join("app/clients")
    config.eager_load_paths << Rails.root.join("app/events")
    config.eager_load_paths << Rails.root.join("app/publishers")
    config.eager_load_paths << Rails.root.join("app/messaging")
  end
end
