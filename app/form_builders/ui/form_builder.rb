module Ui
  class FormBuilder < ActionView::Helpers::FormBuilder
    def ui_text_field(method, **options) = ui_input(method, :text_field, **options)
    def ui_email_field(method, **options) = ui_input(method, :email_field, autocomplete: "email", inputmode: "email", **options)
    def ui_password_field(method, **options) = ui_input(method, :password_field, autocomplete: "current-password", **options)
    def ui_number_field(method, **options) = ui_input(method, :number_field, inputmode: "numeric", **options)
    def ui_decimal_field(method, **options) = ui_input(method, :number_field, step: "any", inputmode: "decimal", **options)
    def ui_date_field(method, **options) = ui_input(method, :date_field, **options)
    def ui_datetime_field(method, **options) = ui_input(method, :datetime_local_field, **options)
    def ui_text_area(method, **options) = ui_input(method, :text_area, **options)

    def ui_select(method, choices, **options)
      presentation, input_options = extract_presentation_options(method, options)
      input_options[:class] = @template.token_list("ui-input", input_options[:class])
      render_field(presentation, select(method, choices, {}, input_options))
    end

    def ui_checkbox(method, **options)
      presentation, input_options = extract_presentation_options(method, options)
      input_options[:class] = @template.token_list("ui-checkbox", input_options[:class])

      @template.render Ui::Forms::CheckboxComponent.new(
        label: presentation[:label],
        input_id: presentation[:input_id],
        input_html: check_box(method, input_options),
        help_text: presentation[:help_text],
        errors: presentation[:errors],
        html_options: presentation[:wrapper_options]
      )
    end

    def ui_radio_group(method, collection, value_method: :first, text_method: :last, **options)
      presentation, input_options = extract_presentation_options(method, options)
      options_html = @template.safe_join(collection.map do |item|
        value = item.public_send(value_method)
        text = item.public_send(text_method)
        id = field_id(method, value)
        radio = radio_button(method, value, input_options.merge(id: id, class: @template.token_list("ui-radio", input_options[:class])))
        @template.tag.label(for: id, class: "ui-radio-group__option") { @template.safe_join([ radio, @template.tag.span(text) ]) }
      end)

      @template.render Ui::Forms::RadioGroupComponent.new(
        legend: presentation[:label],
        input_id: presentation[:input_id],
        options_html: options_html,
        help_text: presentation[:help_text],
        errors: presentation[:errors],
        required: presentation[:required],
        html_options: presentation[:wrapper_options]
      )
    end

    def ui_error_summary(title: nil, html_options: {})
      @template.render Ui::Forms::ErrorSummaryComponent.new(errors: object_errors, title: title, html_options: html_options)
    end

    def ui_submit(value = nil, **options)
      @template.render Ui::ButtonComponent.new(label: value || I18n.t("forms.actions.submit"), type: :submit, html_options: options)
    end

    private

    def ui_input(method, helper, **options)
      presentation, input_options = extract_presentation_options(method, options)
      input_options[:class] = @template.token_list("ui-input", input_options[:class])
      render_field(presentation, public_send(helper, method, input_options))
    end

    def render_field(presentation, input)
      @template.render Ui::Forms::FieldComponent.new(
        label: presentation[:label], input_id: presentation[:input_id], input_html: input,
        help_text: presentation[:help_text], errors: presentation[:errors], required: presentation[:required],
        html_options: presentation[:wrapper_options]
      )
    end

    def extract_presentation_options(method, options)
      options = options.deep_dup
      label = options.delete(:label) || human_label(method)
      help_text = options.delete(:help_text)
      required = options.key?(:required) ? options[:required] : false
      wrapper_options = options.delete(:wrapper_options) || {}
      input_id = options[:id] || field_id(method)
      errors = field_errors(method)
      described_by = []
      described_by << "#{input_id}_help" if help_text.present?
      described_by << "#{input_id}_error" if errors.any?
      options[:id] = input_id
      options[:aria] = (options[:aria] || {}).merge(invalid: errors.any? ? "true" : nil, describedby: described_by.presence&.join(" ")).compact

      [ { label: label, help_text: help_text, required: required, errors: errors, input_id: input_id, wrapper_options: wrapper_options }, options ]
    end

    def field_errors(method)
      object&.respond_to?(:errors) ? object.errors.full_messages_for(method) : []
    end

    def object_errors
      object&.respond_to?(:errors) ? object.errors.full_messages : []
    end

    def human_label(method)
      object&.class&.respond_to?(:human_attribute_name) ? object.class.human_attribute_name(method) : method.to_s.humanize
    end
  end
end
