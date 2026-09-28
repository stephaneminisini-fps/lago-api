# frozen_string_literal: true

module CursorPagination
  # Cursor pagination of a list: passed as the `pagination:` argument of a query, it
  # selects keyset pagination instead of the offset one. Every parameter is validated
  # on initialization, so an invalid request fails before any SQL runs.
  class Cursor
    DEFAULT_LIMIT = 20
    LIMIT_RANGE = (1..100)

    attr_reader :table, :limit, :after, :before, :key

    def self.from_params(params, table:)
      new(
        table:,
        limit: params[:limit],
        after: params[:after],
        before: params[:before],
        include_total_count: params[:include_total_count]
      )
    end

    # `table` is the table of the listed resource: a cursor minted for another table is
    # rejected, even when both resources render under the same name.
    def initialize(table:, limit: nil, after: nil, before: nil, include_total_count: nil)
      @table = table
      @limit = parse_limit(limit)
      @after = parse_token(after, :after)
      @before = parse_token(before, :before)
      @include_total_count = ActiveModel::Type::Boolean.new.cast(include_total_count) || false

      validate_combination!
      @key = Token.decode(token, table:, param: token_param) if token
    end

    def direction
      if after
        :forward
      elsif before
        :backward
      else
        :first
      end
    end

    def backward?
      direction == :backward
    end

    def include_total_count?
      @include_total_count
    end

    def token
      after || before
    end

    private

    def token_param
      after ? :after : :before
    end

    # A silent clamp would return fewer rows than asked, which some clients read as
    # the end of the list, hence an error for any value out of range.
    def parse_limit(value)
      return DEFAULT_LIMIT if value.nil? || value == ""

      limit = if value.is_a?(Integer)
        value
      elsif value.is_a?(String) && value.match?(/\A\d+\z/)
        value.to_i
      end
      return limit if LIMIT_RANGE.cover?(limit)

      raise Error.new(
        code: Error::INVALID_LIMIT,
        details: {limit: {value:, allowed_range: "#{LIMIT_RANGE.first}..#{LIMIT_RANGE.last}"}}
      )
    end

    def parse_token(value, param)
      return if value.nil? || value == ""
      return value if value.is_a?(String)

      raise Error.new(code: Error::INVALID_CURSOR, details: {param => {reason: "malformed"}})
    end

    def validate_combination!
      if after && before
        raise Error.new(
          code: Error::INVALID_CURSOR,
          details: {after: {reason: "exclusive_with_before"}, before: {reason: "exclusive_with_after"}}
        )
      end

      # Keeps the count to one request per iteration: a client resuming from a stored
      # cursor gets the total from a fresh first page.
      if include_total_count? && token
        raise Error.new(
          code: Error::TOTAL_COUNT_FIRST_PAGE_ONLY,
          details: {include_total_count: {reason: "first_page_only"}}
        )
      end
    end
  end
end
