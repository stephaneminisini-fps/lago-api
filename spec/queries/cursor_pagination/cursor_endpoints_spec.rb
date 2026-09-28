# frozen_string_literal: true

require "rails_helper"

# Keyset pagination is only correct when the tuple is the whole ordering of the query:
# a query ordering or filtering after `paginate` would break it silently. Each query
# serving a cursor-paginated v2 list is called with every filter it supports.
RSpec.describe "Cursor-paginated queries" do # rubocop:disable RSpec/DescribeClass
  let(:organization) { create(:organization) }

  def order_and_limit(table)
    %(ORDER BY "#{table}"."created_at" DESC, "#{table}"."id" DESC LIMIT 21)
  end

  context "with ProductsQuery" do
    subject(:products) do
      ProductsQuery.call(
        organization:,
        search_term: "a",
        pagination: CursorPagination::Cursor.new(table: "products"),
        filters: {product_category_ids: [product_category.id], without_product_category: true, product_type: "fixed"}
      ).products
    end

    let(:product_category) { create(:product_category, organization:) }

    it "ends with the keyset ordering" do
      expect(products.to_sql).to end_with(order_and_limit("products"))
    end
  end

  context "with ProductCategoriesQuery" do
    subject(:product_categories) do
      ProductCategoriesQuery.call(
        organization:,
        search_term: "a",
        pagination: CursorPagination::Cursor.new(table: "product_categories")
      ).product_categories
    end

    it "ends with the keyset ordering" do
      expect(product_categories.to_sql).to end_with(order_and_limit("product_categories"))
    end
  end

  context "with RateCardsQuery" do
    subject(:rate_cards) do
      RateCardsQuery.call(
        organization:,
        search_term: "a",
        pagination: CursorPagination::Cursor.new(table: "rate_cards"),
        filters: {
          product_ids: [SecureRandom.uuid],
          product_filter_ids: [SecureRandom.uuid],
          product_category_ids: [SecureRandom.uuid],
          without_product_category: true,
          code: "code",
          product_code: "product",
          product_filter_code: "filter"
        }
      ).rate_cards
    end

    it "ends with the keyset ordering" do
      expect(rate_cards.to_sql).to end_with(order_and_limit("rate_cards"))
    end
  end

  context "with CatalogPlansQuery" do
    subject(:catalog_plans) do
      CatalogPlansQuery.call(
        organization:,
        search_term: "a",
        pagination: CursorPagination::Cursor.new(table: "catalog_plans")
      ).catalog_plans
    end

    it "ends with the keyset ordering" do
      expect(catalog_plans.to_sql).to end_with(order_and_limit("catalog_plans"))
    end
  end

  context "with ContractsQuery" do
    subject(:contracts) do
      ContractsQuery.call(
        organization:,
        search_term: "a",
        pagination: CursorPagination::Cursor.new(table: "contracts"),
        filters: {
          external_customer_id: "customer",
          plan_code: "plan",
          status: ["active"],
          billing_entity_ids: [SecureRandom.uuid],
          has_rate_overrides: "true"
        }
      ).contracts
    end

    it "ends with the keyset ordering" do
      expect(contracts.to_sql).to end_with(order_and_limit("contracts"))
    end
  end
end
