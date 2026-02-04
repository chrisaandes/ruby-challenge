# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customer do
  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to validate_presence_of(:address) }
  end

  describe "attributes" do
    it { is_expected.to have_db_column(:name).of_type(:string) }
    it { is_expected.to have_db_column(:email).of_type(:string) }
    it { is_expected.to have_db_column(:address).of_type(:text) }
    it { is_expected.to have_db_column(:orders_count).of_type(:integer).with_options(default: 0) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:customer)).to be_valid
    end
  end
end
