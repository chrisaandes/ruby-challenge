# frozen_string_literal: true

class Customer < ApplicationRecord
  validates :name, presence: true
  validates :email, presence: true, uniqueness: { case_sensitive: false }
  validates :address, presence: true
end
