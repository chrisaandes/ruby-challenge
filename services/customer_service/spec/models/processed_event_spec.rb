# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProcessedEvent do
  describe "validations" do
    subject { create(:processed_event) }

    it { is_expected.to validate_presence_of(:event_id) }
    it { is_expected.to validate_uniqueness_of(:event_id) }
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:processed_event)).to be_valid
    end
  end
end
