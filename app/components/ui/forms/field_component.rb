module Ui
  module Forms
    class FieldComponent < Ui::BaseComponent
      def initialize(label:, input_id:, input_html:, help_text: nil, errors: [], required: false, html_options: {})
        @label = label
        @input_id = input_id
        @input_html = input_html
        @help_text = help_text
        @errors = Array(errors)
        @required = required
        @html_options = html_options
      end

      def call
        tag.div(**merged_html_options(class: class_names("ui-field", ("ui-field--invalid" if invalid?)))) do
          safe_join([
            label_markup,
            @input_html,
            help_markup,
            error_markup
          ].compact)
        end
      end

      private

      def invalid?
        @errors.any?
      end

      def label_markup
        tag.label(for: @input_id, class: "ui-field__label") do
          safe_join([ @label, required_markup ].compact, " ")
        end
      end

      def required_markup
        return unless @required

        tag.span("*", class: "ui-field__required", aria: { hidden: true })
      end

      def help_markup
        return if @help_text.blank?

        tag.p(@help_text, id: "#{@input_id}_help", class: "ui-field__help")
      end

      def error_markup
        return unless invalid?

        tag.ul(id: "#{@input_id}_error", class: "ui-field__errors") do
          safe_join(@errors.map { |error| tag.li(error) })
        end
      end
    end
  end
end
