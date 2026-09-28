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
end
