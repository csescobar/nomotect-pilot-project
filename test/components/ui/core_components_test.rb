require "test_helper"

class Ui::CoreComponentsTest < ViewComponent::TestCase
  test "button merges HTML attributes and validates variants" do
    render_inline Ui::ButtonComponent.new(
      label: "Save",
      variant: :primary,
      size: :small,
      html_options: { class: "custom", data: { testid: "save" }, aria: { label: "Save record" } }
    )

    assert_selector "button.button.button--primary.button--small.custom[data-testid='save'][aria-label='Save record']"
    assert_raises(ArgumentError) { Ui::ButtonComponent.new(label: "Save", variant: :unknown) }
  end

  test "card renders block content and custom attributes" do
    component = Ui::CardComponent.new(variant: :outlined, html_options: { id: "profile" }).with_content("Profile")
    render_inline component

    assert_selector "section#profile.ui-card.ui-card--outlined", text: "Profile"
  end

  test "badge exposes semantic variant and size" do
    render_inline Ui::BadgeComponent.new(label: "Active", variant: :success, size: :small)

    assert_selector "span.ui-badge.ui-badge--success.ui-badge--small", text: "Active"
  end

  test "danger alert uses assertive role" do
    component = Ui::AlertComponent.new(title: "Error", variant: :danger).with_content("Try again")
    render_inline component

    assert_selector "div.ui-alert.ui-alert--danger[role='alert']"
    assert_selector ".ui-alert__title", text: "Error"
    assert_selector ".ui-alert__body", text: "Try again"
  end

  test "divider exposes its orientation" do
    render_inline Ui::DividerComponent.new(orientation: :vertical)

    assert_selector ".ui-divider--vertical[role='separator'][aria-orientation='vertical']"
  end

  test "empty state connects its heading with aria-labelledby" do
    component = Ui::EmptyStateComponent.new(
      title: "No records",
      description: "Create the first one"
    ).with_content("Action")
    render_inline component

    document = Nokogiri::HTML.fragment(rendered_content)
    section = document.at_css("section.ui-empty-state")
    heading = document.at_css("h2.ui-empty-state__title")

    assert_equal heading["id"], section["aria-labelledby"]
    assert_equal "No records", heading.text
    assert_selector ".ui-empty-state__description", text: "Create the first one"
    assert_selector ".ui-empty-state__actions", text: "Action"
  end
end
