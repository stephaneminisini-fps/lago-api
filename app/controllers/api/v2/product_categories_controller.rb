# frozen_string_literal: true

module Api
  module V2
    class ProductCategoriesController < Api::V2::BaseController
      include Api::RequiresProductCatalog

      def create
        result = ::ProductCategories::CreateService.call(
          organization: current_organization,
          params: input_params.to_h.symbolize_keys
        )

        if result.success?
          render_product_category(result.product_category)
        else
          render_error_response(result)
        end
      end

      def update
        product_category = current_organization.product_categories.find_by(code: params[:code])
        result = ::ProductCategories::UpdateService.call(product_category:, params: update_params.to_h.symbolize_keys)

        if result.success?
          render_product_category(result.product_category)
        else
          render_error_response(result)
        end
      end

      def destroy
        product_category = current_organization.product_categories.find_by(code: params[:code])
        result = ::ProductCategories::DestroyService.call(product_category:)

        if result.success?
          render_product_category(result.product_category)
        else
          render_error_response(result)
        end
      end

      def show
        product_category = current_organization.product_categories.find_by(code: params[:code])

        return not_found_error(resource: "product_category") unless product_category

        render_product_category(product_category)
      end

      def index
        cursor = cursor_pagination(ProductCategory)
        result = index_query(pagination: cursor)

        if result.success?
          # Preloaded so products_count reads the loaded association.
          page = ::CursorPagination::Page.new(records: result.product_categories.includes(:products), cursor:)

          render(
            json: ::CollectionSerializer.new(
              page.records,
              ::V2::ProductCategorySerializer,
              collection_name: "product_categories",
              meta: cursor_meta(page) { index_query(pagination: nil).product_categories }
            )
          )
        else
          render_error_response(result)
        end
      end

      private

      def index_query(pagination:)
        ::ProductCategoriesQuery.call(
          organization: current_organization,
          search_term: params[:search_term],
          pagination:
        )
      end

      def input_params
        params.require(:product_category).permit(
          :name,
          :code,
          :description,
          :invoice_display_name
        )
      end

      def update_params
        params.require(:product_category).permit(
          :name,
          :code,
          :description,
          :invoice_display_name
        )
      end

      def render_product_category(product_category)
        render(json: ::V2::ProductCategorySerializer.new(product_category, root_name: "product_category"))
      end

      def resource_name
        "product_category"
      end
    end
  end
end
