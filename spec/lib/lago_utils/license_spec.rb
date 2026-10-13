# frozen_string_literal: true

require "rails_helper"

RSpec.describe LagoUtils::License do
  subject(:license) { described_class.new }

  it "is not premium before verification" do
    expect(license).not_to be_premium
  end

  describe "#verify" do
    it "sets premium to true without a license key" do
      license.verify

      expect(license).to be_premium
    end

    it "does not call a remote license server" do
      license.verify

      expect(a_request(:any, //)).not_to have_been_made
    end
  end
end
