# frozen_string_literal: true

class AddRateCardsCursorIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :rate_cards,
      [:organization_id, :created_at, :id],
      order: {created_at: :desc, id: :desc},
      where: "deleted_at IS NULL",
      name: :index_rate_cards_by_cursor,
      algorithm: :concurrently,
      if_not_exists: true
  end
end
