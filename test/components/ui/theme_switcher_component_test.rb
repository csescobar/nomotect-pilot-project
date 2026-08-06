require "test_helper"

class Ui::ThemeSwitcherComponentTest < ViewComponent::TestCase
  test "renders only light and dark preferences" do
    render_inline Ui::ThemeSwitcherComponent.new

    assert_selector "[data-controller='theme']"
    assert_selector "select[data-action='theme#change'] option", count: 2
    assert_selector "option[value='light']"
    assert_selector "option[value='dark']"
    assert_no_selector "option[value='system']"
  end
end
