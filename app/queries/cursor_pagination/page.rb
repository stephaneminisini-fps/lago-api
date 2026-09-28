# frozen_string_literal: true

module CursorPagination
  # One page of a keyset-paginated relation: loads it once, drops the extra row fetched
  # by `Keyset`, restores the list order when paging backward, and builds the cursors.
  class Page
    attr_reader :cursor

    def initialize(records:, cursor:)
      @relation = records
      @cursor = cursor
    end

    def records
      load_records unless defined?(@records)
      @records
    end

    def meta(total_count: nil)
      meta = {next_cursor:, prev_cursor:}
      return meta unless total_count

      meta[:total_count] = total_count.value
      meta[:total_count_estimated] = true if total_count.estimated
      meta
    end

    private

    attr_reader :relation

    def load_records
      rows = relation.to_a
      @has_more = rows.size > cursor.limit

      rows = rows.first(cursor.limit)
      rows.reverse! if cursor.backward?
      @records = rows
    end

    def has_more?
      records
      @has_more
    end

    # An empty page only happens after deletions. The cursor pointing back echoes the
    # incoming one, used as a strict bound, so the anchor row is not returned again.
    def next_cursor
      case cursor.direction
      when :first, :forward
        encode(records.last) if has_more?
      when :backward
        records.empty? ? cursor.before : encode(records.last)
      end
    end

    def prev_cursor
      case cursor.direction
      when :forward
        records.empty? ? cursor.after : encode(records.first)
      when :backward
        encode(records.first) if has_more?
      end
    end

    def encode(record)
      Token.encode(table: cursor.table, record:)
    end
  end
end
