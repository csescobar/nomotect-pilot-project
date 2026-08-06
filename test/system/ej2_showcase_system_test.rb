require "application_system_test_case"

# EJ2 Showcase Real-Browser System Tests — Phase 6 Automation
class Ej2ShowcaseSystemTest < ApplicationSystemTestCase
  test "visiting the EJ2 showcase forms section and interacting with inputs" do
    visit ej2_showcase_path(section: "forms")

    assert_selector "h1", text: /Mostruário de Componentes EJ2|EJ2 Component Showcase/i
    assert_selector "#ej2-forms-textbox"
    assert_selector "#demo-textbox"
  end

  test "visiting the EJ2 showcase buttons section and testing button loading state" do
    visit ej2_showcase_path(section: "buttons")

    assert_selector "#ej2-buttons-variants"
    assert_selector "#ej2-buttons-states"

    click_button I18n.t("ej2_showcase.buttons.states.trigger_loading")
    assert_selector "button.is-loading"
  end

  test "visiting the EJ2 showcase dialogs section and opening confirmation modal" do
    visit ej2_showcase_path(section: "dialogs")

    assert_selector "#ej2-dialogs-confirmation"
    click_button I18n.t("ej2_showcase.dialogs.confirmation.trigger")

    assert_selector ".e-dialog"
    assert_selector ".e-dlg-header", text: I18n.t("ej2_showcase.dialogs.confirmation.header")

    click_button I18n.t("ej2_showcase.dialogs.confirmation.cancel_btn")
  end

  test "visiting the EJ2 showcase cards section and toggling collapsible panel" do
    visit ej2_showcase_path(section: "cards")

    assert_selector "#ej2-cards-collapsible"
    assert_selector "[data-controller='ej2-card']"

    find(".ej2-collapsible-card__header").click
    assert_no_selector ".ej2-collapsible-card__content.is-collapsed"

    find(".ej2-collapsible-card__header").click
    assert_selector ".ej2-collapsible-card__content.is-collapsed", visible: false
  end

  test "visiting the EJ2 showcase toolbar section and rendering action items" do
    visit ej2_showcase_path(section: "toolbar")

    assert_selector "#ej2-toolbar-standard"
    assert_selector "#ej2-toolbar-overflow"
    assert_selector ".e-toolbar", minimum: 2
  end

  test "visiting the EJ2 showcase data grid section and rendering enterprise table" do
    visit ej2_showcase_path(section: "grid")

    assert_selector "#ej2-grid-showcase"
    assert_selector "[data-controller='ej2-grid']"
    assert_selector ".ej2-grid-container"
  end

  test "visiting the EJ2 showcase toasts section and triggering toast feedback" do
    visit ej2_showcase_path(section: "toasts")

    assert_selector "#ej2-toasts-demo"
    click_button I18n.t("ej2_showcase.toasts.demo.success_btn")

    assert_selector ".e-toast.e-toast-success"
    assert_selector ".e-toast-title", text: "Success"
  end

  test "visiting the EJ2 showcase loading section and toggling spinner overlay" do
    visit ej2_showcase_path(section: "loading")

    assert_selector "#ej2-loading-spinner"
    assert_selector "#ej2-loading-skeleton"

    click_button I18n.t("ej2_showcase.loading.spinner.toggle")
    assert_selector ".e-spinner-pane"
  end
end
