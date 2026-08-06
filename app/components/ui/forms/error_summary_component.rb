module Ui
  module Forms
    class ErrorSummaryComponent < Ui::BaseComponent
      def initialize(errors:, title: nil, html_options: {})
        @errors = Array(errors)
        @title = title || I18n.t("forms.errors.summary_title")
        @html_options = html_options
      end

      def render?
        @errors.any?
      end

      def call
        tag.div(**merged_html_options(class: "ui-error-summary", role: "alert", tabindex: -1)) do
          safe_join([
            tag.h2(@title, class: "ui-error-summary__title"),
            tag.ul(class: "ui-error-summary__list") do
              safe_join(@errors.map { |error| tag.li(error) })
            end
          ])
        end
      end
    end
  end
end
