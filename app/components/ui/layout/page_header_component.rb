module Ui
  module Layout
    class PageHeaderComponent < Ui::BaseComponent
      def initialize(title:, description: nil, html_options: {})
        @title = title
        @description = description
        @html_options = html_options
      end

      def call
        tag.header(**merged_html_options(class: "page-header")) do
          safe_join([
            tag.div(class: "page-header__copy") do
              safe_join([
                tag.h1(@title, class: "page-header__title"),
                (tag.p(@description, class: "page-header__description") if @description.present?)
              ].compact)
            end,
            (tag.div(content, class: "page-header__actions") if content.present?)
          ].compact)
        end
      end
    end
  end
end
