# Form components

`Ui::FormBuilder` is the Rails integration boundary for the design system. It reads model metadata and validation errors, then passes normalized values to ViewComponents that own the rendered markup.

## Usage

```erb
<%= form_with model: @user, builder: Ui::FormBuilder do |form| %>
  <%= form.ui_error_summary %>
  <%= form.ui_text_field :name, help_text: t("users.form.name_help"), required: true %>
  <%= form.ui_email_field :email_address %>
  <%= form.ui_select :locale, locale_options %>
  <%= form.ui_checkbox :active %>
  <%= form.ui_submit %>
<% end %>
```

## Supported controls

Text, email, password, integer, decimal, date, local datetime, textarea, select, checkbox, radio group, submit, and validation summary are included.

## Contract

- Labels default to `human_attribute_name` and may be overridden.
- Help and error content receive stable IDs and are connected through `aria-describedby`.
- Invalid controls expose `aria-invalid="true"`.
- Required indicators are visual supplements; the native `required` attribute remains authoritative.
- Builder methods accept normal Rails input options plus `label`, `help_text`, and `wrapper_options`.
- Visible text must be supplied through Rails I18n in application code.
- New controls must reuse the field/error contract rather than duplicating accessibility markup.

Complex widgets such as autocomplete, rich text, file upload, multiselect, date ranges, and nested dynamic forms are intentionally outside this foundation.
