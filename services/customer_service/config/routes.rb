# frozen_string_literal: true

Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      resources :customers, only: [:show]
    end
  end

  get "health", to: proc { [200, {}, ["OK"]] }
  get "health/rabbitmq", to: "health#rabbitmq"
end
