# frozen_string_literal: true

class AddContractsCursorIndex < ActiveRecord::Migration[8.0]
  disable_ddl_transaction!

  def change
    add_index :contracts,
      [:organization_id, :created_at, :id],
      order: {created_at: :desc, id: :desc},
      name: :index_contracts_by_cursor,
      algorithm: :concurrently,
      if_not_exists: true
  end
end
