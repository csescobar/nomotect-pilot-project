module Ui
  module Forms
    class RadioGroupComponent < Ui::BaseComponent
      def initialize(legend:, input_id:, options_html:, help_text: nil, errors: [], required: false, html_options: {})
        @legend = legend
        @input_id = input_id
        @options_html = options_html
        @help_text = help_text
        @errors = Array(errors)
        @required = required
        @html_options = html_options
      end

      def call
        tag.fieldset(**merged_html_options(class: class_names("ui-field", "ui-radio-group", ("ui-field--invalid" if @errors.any?)))) do
          safe_join([
            tag.legend(class: "ui-field__label") { safe_join([ @legend, required_markup ].compact, " ") },
            tag.div(@options_html, class: "ui-radio-group__options"),
            help_markup,
            error_markup
          ].compact)
        end
      end

      private

      def required_markup
        return unless @required

        tag.span("*", class: "ui-field__required", aria: { hidden: true })
      end

      def help_markup
        return if @help_text.blank?

        tag.p(@help_text, id: "#{@input_id}_help", class: "ui-field__help")
      end

      def error_markup
        return if @errors.empty?

        tag.ul(id: "#{@input_id}_error", class: "ui-field__errors") { safe_join(@errors.map { |error| tag.li(error) }) }
      end
    end
  end
end
