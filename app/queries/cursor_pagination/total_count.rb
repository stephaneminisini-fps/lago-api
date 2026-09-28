# frozen_string_literal: true

module CursorPagination
  # Total of an unpaginated relation, for the first page of a cursor-paginated list.
  #
  # Exact below the cap. Beyond it, or when the count times out, it falls back to the
  # planner's row estimate, flagged as estimated. The estimate alone is unreliable with
  # correlated filters and between two `ANALYZE`, hence only used where precision
  # matters least, and never reported below the cap once the cap is reached.
  class TotalCount
    MAX_COUNTED_RECORDS = 10_000
    DEFAULT_TIMEOUT_MS = 2_000

    Result = Data.define(:value, :estimated)

    def self.call(relation)
      new(relation).call
    end

    def initialize(relation)
      @relation = relation.except(:order, :limit, :offset, :includes, :preload, :eager_load)
    end

    def call
      counted = capped_count
      return Result.new(value: counted, estimated: false) if counted <= MAX_COUNTED_RECORDS

      Result.new(value: [planner_estimate, counted].max, estimated: true)
    rescue ActiveRecord::QueryCanceled
      Result.new(value: planner_estimate, estimated: true)
    end

    private

    attr_reader :relation

    # Counts one past the cap, so that a list landing exactly on it is reported exactly.
    # `SET LOCAL` confines the timeout to the transaction wrapping the count.
    def capped_count
      relation.transaction(requires_new: true) do
        relation.connection.execute("SET LOCAL statement_timeout = #{timeout_ms}")
        relation.limit(MAX_COUNTED_RECORDS + 1).count
      end
    end

    def planner_estimate
      plan = relation.connection.select_value("EXPLAIN (FORMAT JSON) #{relation.to_sql}")
      plan = JSON.parse(plan) if plan.is_a?(String)
      plan.dig(0, "Plan", "Plan Rows").to_i
    end

    def timeout_ms
      timeout = ENV["LAGO_API_TOTAL_COUNT_TIMEOUT_MS"].to_i
      timeout.positive? ? timeout : DEFAULT_TIMEOUT_MS
    end
  end
end
