require "test_helper"

class Ui::DangerZoneComponentTest < ViewComponent::TestCase
  test "renders labelled destructive content" do
    render_inline Ui::DangerZoneComponent.new(
      id: "record-danger",
      title: "Danger zone",
      description: "This cannot be undone."
    ) do
      ApplicationController.helpers.tag.button("Delete", class: "button button--danger")
    end

    assert_selector "section.ui-danger-zone[aria-labelledby='record-danger-title']"
    assert_selector "#record-danger-title", text: "Danger zone"
    assert_selector ".ui-danger-zone__description", text: "This cannot be undone."
    assert_selector ".ui-danger-zone__actions .button--danger", text: "Delete"
  end
end
