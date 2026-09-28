# frozen_string_literal: true

class AddCatalogPlansCursorIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :catalog_plans,
      [:organization_id, :created_at, :id],
      order: {created_at: :desc, id: :desc},
      where: "deleted_at IS NULL",
      name: :index_catalog_plans_by_cursor,
      algorithm: :concurrently,
      if_not_exists: true
  end
end
