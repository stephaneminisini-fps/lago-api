# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API v2 beta header" do
  let(:organization) { create(:organization) }

  it "is set on a successful response" do
    get_with_token(organization, "/api/v2/plans")

    expect(response).to have_http_status(:success)
    expect(response.headers["X-Lago-Endpoint-Status"]).to eq("beta")
  end

  it "is set on an unauthorized response" do
    get("/api/v2/plans", headers: {"Authorization" => "Bearer invalid"})

    expect(response).to have_http_status(:unauthorized)
    expect(response.headers["X-Lago-Endpoint-Status"]).to eq("beta")
  end

  context "when the organization is not on the product catalog", product_catalog: false do
    it "is set on a forbidden response" do
      get_with_token(organization, "/api/v2/plans")

      expect(response).to have_http_status(:forbidden)
      expect(response.headers["X-Lago-Endpoint-Status"]).to eq("beta")
    end
  end

  it "is not set on the v1-backed fallthrough paths" do
    get_with_token(organization, "/api/v2/billable_metrics")

    expect(response).to have_http_status(:success)
    expect(response.headers).not_to have_key("X-Lago-Endpoint-Status")
  end
end
