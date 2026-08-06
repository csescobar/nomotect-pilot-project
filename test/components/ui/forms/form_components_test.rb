require "test_helper"

class Ui::Forms::FormComponentsTest < ViewComponent::TestCase
  class Profile
    include ActiveModel::Model

    attr_accessor :name, :email, :password, :age, :rate, :birthday, :starts_at, :notes, :locale, :active, :role

    validates :email, presence: true

    def self.model_name
      ActiveModel::Name.new(self, nil, "Profile")
    end
  end

  class HarnessComponent < ViewComponent::Base
    def initialize(record:)
      @record = record
    end

    def call
      form_with(model: @record, url: "/profiles", builder: Ui::FormBuilder) do |form|
        safe_join([
          form.ui_error_summary,
          form.ui_text_field(:name, label: "Name", help_text: "Your public name", required: true),
          form.ui_email_field(:email),
          form.ui_password_field(:password),
          form.ui_number_field(:age),
          form.ui_decimal_field(:rate),
          form.ui_date_field(:birthday),
          form.ui_datetime_field(:starts_at),
          form.ui_text_area(:notes),
          form.ui_select(:locale, [ [ "English", "en" ], [ "Português", "pt-BR" ] ]),
          form.ui_checkbox(:active, label: "Active", help_text: "Allow access"),
          form.ui_radio_group(:role, [ [ "admin", "Administrator" ], [ "member", "Member" ] ], label: "Role"),
          form.ui_submit("Save")
        ])
      end
    end
  end

  test "builder renders accessible field contracts" do
    render_inline HarnessComponent.new(record: Profile.new)

    assert_selector "label[for='profile_name']", text: "Name"
    assert_selector "#profile_name.ui-input[required][aria-describedby='profile_name_help']"
    assert_selector "#profile_name_help", text: "Your public name"
    assert_selector "input[type='email'][autocomplete='email'][inputmode='email']"
    assert_selector "input[type='number'][inputmode='decimal'][step='any']"
    assert_selector "input[type='date']"
    assert_selector "input[type='datetime-local']"
    assert_selector "textarea.ui-input"
    assert_selector "select.ui-input"
    assert_selector ".ui-checkbox-field label", text: "Active"
    assert_selector "fieldset.ui-radio-group legend", text: "Role"
    assert_selector "button.button[type='submit']", text: "Save"
  end

  test "builder connects model errors to fields and summary" do
    record = Profile.new
    record.validate
    render_inline HarnessComponent.new(record: record)

    assert_selector ".ui-error-summary[role='alert'] li", text: "Email can't be blank"
    assert_selector ".ui-field--invalid #profile_email[aria-invalid='true'][aria-describedby='profile_email_error']"
    assert_selector "#profile_email_error li", text: "Email can't be blank"
  end

  test "error summary does not render without errors" do
    render_inline Ui::Forms::ErrorSummaryComponent.new(errors: [])

    assert_no_selector ".ui-error-summary"
  end
end
