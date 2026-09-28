# frozen_string_literal: true

require "rails_helper"

RSpec.describe CursorPagination::TotalCount do
  subject(:total_count) { described_class.call(relation) }

  let(:organization) { create(:organization) }
  let(:relation) { Product.where(organization:).includes(:product_category).order(:name).limit(1) }

  before { create_list(:product, 3, organization:) }

  context "when the list is below the cap" do
    it "returns the exact count, ignoring order and limit" do
      expect(total_count).to eq(described_class::Result.new(value: 3, estimated: false))
    end
  end

  context "when the list lands exactly on the cap" do
    before { stub_const("#{described_class}::MAX_COUNTED_RECORDS", 3) }

    it "returns the exact count" do
      expect(total_count).to eq(described_class::Result.new(value: 3, estimated: false))
    end
  end

  context "when the list is beyond the cap" do
    before { stub_const("#{described_class}::MAX_COUNTED_RECORDS", 1) }

    it "returns an estimate, never below the cap" do
      expect(total_count.estimated).to be(true)
      expect(total_count.value).to be >= 2
    end
  end

  context "when the count times out" do
    let(:relation) { Product.where(organization:).where("(SELECT pg_sleep(0.2)) IS NULL") }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("LAGO_API_TOTAL_COUNT_TIMEOUT_MS").and_return("10")
    end

    it "returns the planner's estimate" do
      expect(total_count.estimated).to be(true)
      expect(total_count.value).to be_a(Integer)
    end
  end
end
