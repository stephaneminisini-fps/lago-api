# frozen_string_literal: true

class AddPlanRateCardsCursorIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :plan_rate_cards,
      [:catalog_plan_id, :created_at, :id],
      order: {created_at: :desc, id: :desc},
      where: "deleted_at IS NULL",
      name: :index_plan_rate_cards_by_cursor,
      algorithm: :concurrently,
      if_not_exists: true
  end
end
