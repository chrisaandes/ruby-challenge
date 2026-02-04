# frozen_string_literal: true

namespace :rabbitmq do
  desc "Setup RabbitMQ exchanges and queues"
  task setup: :environment do
    MessagingConfig.setup!
    puts "RabbitMQ setup complete!"
  end

  desc "Check RabbitMQ connection"
  task status: :environment do
    if RabbitMQ.connected?
      puts "RabbitMQ: Connected"
    else
      puts "RabbitMQ: Disconnected"
      exit 1
    end
  end
end
