# frozen_string_literal: true

namespace :consumers do
  desc "Start all consumers"
  task start: :environment do
    require "sneakers/runner"

    Sneakers::Runner.new([OrderCreatedConsumer]).run
  end

  desc "Start order created consumer only"
  task order_created: :environment do
    require "sneakers/runner"

    Sneakers::Runner.new([OrderCreatedConsumer]).run
  end
end
