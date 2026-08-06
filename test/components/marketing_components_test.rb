require "test_helper"

class MarketingComponentsTest < ViewComponent::TestCase
  test "renders HeaderComponent" do
    render_inline(Marketing::HeaderComponent.new(authenticated: false))

    assert_selector "header.mkt-header"
    assert_selector "img[alt='NomoTect']"
  end

  test "renders HeroComponent" do
    render_inline(Marketing::HeroComponent.new)

    assert_selector ".mkt-hero__headline"
    assert_text "Build with structure."
  end

  test "renders ProductPreviewComponent" do
    render_inline(Marketing::ProductPreviewComponent.new)

    assert_selector ".mkt-preview-frame"
    assert_text "Organization Customers"
  end

  test "renders CapabilityComponent" do
    render_inline(Marketing::CapabilityComponent.new)

    assert_selector "#capabilities"
    assert_text "Application Foundation"
  end
end
