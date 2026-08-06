require "test_helper"

class Ui::LocaleSwitcherComponentTest < ViewComponent::TestCase
  test "renders supported locales and current selection" do
    render_inline Ui::LocaleSwitcherComponent.new(current_locale: "pt-BR", action: "/locale_preference")

    assert_selector "form.locale-switcher[method='post']"
    assert_selector "label[for='locale']", text: "Language"
    assert_selector "select#locale[name='locale'][aria-label='Language'] option[selected][value='pt-BR']"
    assert_selector "option[value='en']", text: "English"
    assert_selector "option[value='pt-BR']", text: "Português (Brasil)"
    assert_selector "noscript input[type='submit']"
  end
end
