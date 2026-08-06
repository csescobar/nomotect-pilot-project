module Ui
  module Layout
    class NavigationComponent < Ui::BaseComponent
      def initialize(items:, label:, html_options: {})
        @items = items
        @label = label
        @html_options = html_options
      end

      def call
        tag.nav(**merged_html_options(class: "app-navigation", aria: { label: @label })) do
          tag.ul(class: "app-navigation__list") { safe_join(@items.map { |item| render_item(item) }) }
        end
      end

      private

      def render_item(item)
        tag.li(class: "app-navigation__item") do
          safe_join([
            link_to(item[:href], class: class_names("app-navigation__link", ("is-active" if item[:active])), aria: { current: ("page" if item[:active]) }, data: item[:data]) do
              safe_join([
                (tag.span(item[:icon], class: "app-navigation__icon", aria: { hidden: true }) if item[:icon]),
                tag.span(item.fetch(:label), class: "app-navigation__label"),
                (tag.span(item[:badge], class: "app-navigation__badge") if item[:badge])
              ].compact)
            end,
            (tag.ul(class: "app-navigation__children") { safe_join(item[:children].map { |child| render_item(child) }) } if item[:children].present?)
          ].compact)
        end
      end
    end
  end
end
