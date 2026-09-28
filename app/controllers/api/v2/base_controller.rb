# frozen_string_literal: true

module Api
  module V2
    class BaseController < Api::BaseController
      # Prepended, so that it runs before the authentication and authorization callbacks
      # and 401 and 403 responses carry the header too: v2 is beta by contract.
      prepend_before_action :set_beta_header!

      rescue_from ::CursorPagination::Error, with: :pagination_error

      private

      def cursor_pagination(model)
        ::CursorPagination::Cursor.from_params(params, table: model.table_name)
      end

      # The block returns the unpaginated relation, only counted when the client asks.
      def cursor_meta(page)
        return page.meta unless page.cursor.include_total_count?

        page.meta(total_count: ::CursorPagination::TotalCount.call(yield))
      end

      def pagination_error(error)
        invalid_request_error(code: error.code, error_details: error.details)
      end

      # Every v2 400 shares this body, keyed by the offending parameter.
      def invalid_request_error(code:, error_details:)
        render(
          json: {
            status: 400,
            error: "Bad Request",
            code:,
            error_details:
          },
          status: :bad_request
        )
      end
    end
  end
end
