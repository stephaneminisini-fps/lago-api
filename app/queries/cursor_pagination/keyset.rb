# frozen_string_literal: true

module CursorPagination
  # Positions a scope on a cursor. Every cursor endpoint sorts on the same tuple, so a
  # single row-value comparison bounds the page and an index on the tuple serves it.
  module Keyset
    SORT = {created_at: :desc, id: :desc}.freeze
    SIGNATURE = SORT.map { |column, direction| "#{column}:#{direction}" }.join(",").freeze

    # Must be the last scope operation of a query: `reorder` drops any ordering applied
    # before it, and a later `order` would be appended after the tuple.
    def self.apply(scope, cursor)
      if scope.table_name != cursor.table
        raise ArgumentError, "cursor minted for #{cursor.table} applied to #{scope.table_name}"
      end

      scope = case cursor.direction
      when :forward
        scope.where("#{row(scope)} < (?, ?)", *cursor.key).reorder(SORT)
      when :backward
        # Walks towards the start of the list, so the rows closest to the anchor come
        # first. `Page` restores the list order.
        scope.where("#{row(scope)} > (?, ?)", *cursor.key).reorder(SORT.transform_values { :asc })
      else
        scope.reorder(SORT)
      end

      # One extra row tells whether the list continues in the direction being paged.
      scope.limit(cursor.limit + 1)
    end

    def self.row(scope)
      columns = SORT.keys.map { |column| "#{scope.quoted_table_name}.#{scope.connection.quote_column_name(column)}" }
      "(#{columns.join(", ")})"
    end
    private_class_method :row
  end
end
