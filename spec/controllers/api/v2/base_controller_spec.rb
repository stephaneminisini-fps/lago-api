# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::BaseController, type: :controller do
  include ApiHelper

  controller(described_class) do
    def index
      cursor = cursor_pagination(Product)
      page = ::CursorPagination::Page.new(
        records: ::CursorPagination::Keyset.apply(current_organization.products, cursor),
        cursor:
      )

      render(json: {products: page.records.map(&:id), meta: cursor_meta(page) { current_organization.products }})
    end

    private

    def resource_name
      "product"
    end
  end

  subject(:index) { get(:index, params:) }

  let(:organization) { create(:organization) }
  let(:params) { {} }
  let(:products) { create_list(:product, 3, organization:).sort_by { [it.created_at, it.id] }.reverse }

  before do
    products
    request.headers["Authorization"] = "Bearer #{organization.api_keys.first.value}"
  end

  it "sets the beta header" do
    index

    expect(response).to have_http_status(:success)
    expect(response.headers["X-Lago-Endpoint-Status"]).to eq("beta")
  end

  context "without a valid API key" do
    before { request.headers["Authorization"] = "Bearer invalid" }

    it "sets the beta header on the unauthorized response" do
      index

      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["X-Lago-Endpoint-Status"]).to eq("beta")
    end
  end

  context "with a limit" do
    let(:params) { {limit: "2"} }

    it "returns the page and its cursors" do
      index

      expect(json[:products]).to eq(products.first(2).map(&:id))
      expect(json[:meta]).to eq(
        next_cursor: CursorPagination::Token.encode(table: "products", record: products[1]),
        prev_cursor: nil
      )
    end
  end

  context "with include_total_count" do
    let(:params) { {limit: "2", include_total_count: "true"} }

    it "adds the total count" do
      index

      expect(json[:meta][:total_count]).to eq(3)
      expect(json[:meta]).not_to have_key(:total_count_estimated)
    end
  end

  context "with an invalid limit" do
    let(:params) { {limit: "101"} }

    it "returns a bad request error keyed by the parameter" do
      index

      expect(response).to have_http_status(:bad_request)
      expect(json).to eq(
        status: 400,
        error: "Bad Request",
        code: "invalid_pagination_limit",
        error_details: {limit: {value: "101", allowed_range: "1..100"}}
      )
    end
  end

  context "with an invalid cursor" do
    let(:params) { {after: "a"} }

    it "returns a bad request error" do
      index

      expect(response).to have_http_status(:bad_request)
      expect(json[:code]).to eq("invalid_pagination_cursor")
      expect(json[:error_details]).to eq(after: {reason: "malformed"})
    end
  end

  context "with include_total_count on a later page" do
    let(:params) { {include_total_count: "true", after: CursorPagination::Token.encode(table: "products", record: products[0])} }

    it "returns a bad request error" do
      index

      expect(response).to have_http_status(:bad_request)
      expect(json[:code]).to eq("total_count_first_page_only")
    end
  end
end
