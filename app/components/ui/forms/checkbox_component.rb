module Ui
  module Forms
    class CheckboxComponent < Ui::BaseComponent
      def initialize(label:, input_id:, input_html:, help_text: nil, errors: [], html_options: {})
        @label = label
        @input_id = input_id
        @input_html = input_html
        @help_text = help_text
        @errors = Array(errors)
        @html_options = html_options
      end

      def call
        tag.div(**merged_html_options(class: class_names("ui-field", "ui-checkbox-field", ("ui-field--invalid" if @errors.any?)))) do
          safe_join([
            tag.label(for: @input_id, class: "ui-checkbox-field__label") { safe_join([ @input_html, tag.span(@label) ]) },
            help_markup,
            error_markup
          ].compact)
        end
      end

      private

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
