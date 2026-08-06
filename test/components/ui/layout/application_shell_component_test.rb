require "test_helper"

class Ui::Layout::ApplicationShellComponentTest < ViewComponent::TestCase
  UserStub = Struct.new(:email_address)

  test "renders accessible landmarks, active navigation, breadcrumbs, and page heading" do
    component = Ui::Layout::ApplicationShellComponent.new(
      navigation_items: [
        { label: "Dashboard", href: "/", active: true, icon: "⌂" },
        { label: "Settings", href: "/settings", children: [ { label: "Profile", href: "/profile" } ] }
      ],
      current_user: UserStub.new("person@example.com"),
      breadcrumbs: [ { label: "Home", href: "/" }, { label: "Dashboard" } ],
      page_title: "Dashboard",
      page_description: "Platform overview"
    ).with_content("Content")

    render_inline component

    assert_selector "a.skip-link[href='#main-content']"
    assert_selector "header.application-shell__header"
    assert_selector "nav[aria-label='Primary navigation']"
    assert_selector "aside#application-sidebar"
    assert_selector "main#main-content[tabindex='-1']", text: "Content"
    assert_selector "a[aria-current='page']", text: "Dashboard"
    assert_selector ".app-navigation__children a", text: "Profile"
    assert_selector "nav[aria-label='Breadcrumbs'] [aria-current='page']", text: "Dashboard"
    assert_selector "h1.page-header__title", text: "Dashboard"
    assert_selector "details.account-menu summary[aria-label='Account'] .application-shell__account", text: "person@example.com"
    assert_selector ".account-menu__avatar", text: "P"
  end

  test "mobile toggle exposes drawer state and custom attributes are merged" do
    render_inline Ui::Layout::ApplicationShellComponent.new(
      navigation_items: [],
      html_options: { class: "custom-shell", data: { testid: "shell" } }
    )

    assert_selector ".application-shell.custom-shell[data-testid='shell'][data-controller='navigation-drawer']"
    assert_selector "button.navigation-toggle[aria-expanded='false'][aria-controls='application-sidebar']"
    assert_selector "button.navigation-backdrop[data-navigation-drawer-target='backdrop'][hidden]", visible: :all
  end
end
