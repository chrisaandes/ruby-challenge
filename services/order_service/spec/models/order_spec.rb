# frozen_string_literal: true

require "rails_helper"

RSpec.describe Order do
  describe "validations" do
    it { is_expected.to validate_presence_of(:customer_id) }
    it { is_expected.to validate_presence_of(:product_name) }
    it { is_expected.to validate_presence_of(:quantity) }
    it { is_expected.to validate_presence_of(:price) }
    it { is_expected.to validate_presence_of(:status) }

    it { is_expected.to validate_numericality_of(:quantity).is_greater_than(0).only_integer }
    it { is_expected.to validate_numericality_of(:price).is_greater_than(0) }
    it { is_expected.to validate_numericality_of(:customer_id).only_integer }
  end

  describe "attributes" do
    it { is_expected.to have_db_column(:customer_id).of_type(:integer) }
    it { is_expected.to have_db_column(:product_name).of_type(:string) }
    it { is_expected.to have_db_column(:quantity).of_type(:integer) }
    it { is_expected.to have_db_column(:price).of_type(:decimal) }
    it { is_expected.to have_db_column(:status).of_type(:integer) }
    it { is_expected.to have_db_index(:customer_id) }
  end

  describe "enums" do
    it {
      expect(described_class.new).to define_enum_for(:status)
        .with_values(pending: 0, confirmed: 1, shipped: 2, delivered: 3, cancelled: 4)
    }
  end

  describe "scopes" do
    describe ".by_customer" do
      let!(:order_1) { create(:order, customer_id: 1) }
      let!(:order_2) { create(:order, customer_id: 2) }
      let!(:order_3) { create(:order, customer_id: 1) }

      it "returns orders for specific customer" do
        expect(described_class.by_customer(1)).to contain_exactly(order_1, order_3)
      end
    end
  end

  describe "factory" do
    it "has a valid factory" do
      expect(build(:order)).to be_valid
    end
  end

  describe "#total_amount" do
    it "calculates price * quantity" do
      order = build(:order, price: 100.50, quantity: 3)
      expect(order.total_amount).to eq(301.50)
    end
  end
end
