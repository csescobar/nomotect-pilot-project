require "test_helper"

class Ui::ButtonComponentTest < ViewComponent::TestCase
  test "renders a link variant" do
    render_inline Ui::ButtonComponent.new(label: "Health", href: "/health")

    assert_selector "a.button.button--primary[href='/health']", text: "Health"
  end
end
