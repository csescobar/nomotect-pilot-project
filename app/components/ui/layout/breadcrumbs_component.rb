module Ui
  module Layout
    class BreadcrumbsComponent < Ui::BaseComponent
      def initialize(items:, label: I18n.t("layout.breadcrumbs"), html_options: {})
        @items = items
        @label = label
        @html_options = html_options
      end

      def call
        tag.nav(**merged_html_options(class: "breadcrumbs", aria: { label: @label })) do
          tag.ol(class: "breadcrumbs__list") do
            safe_join(@items.map.with_index { |item, index| render_item(item, index == @items.length - 1) })
          end
        end
      end

      private

      def render_item(item, current)
        tag.li(class: "breadcrumbs__item") do
          current ? tag.span(item.fetch(:label), aria: { current: "page" }) : link_to(item.fetch(:label), item.fetch(:href))
        end
      end
    end
  end
end
