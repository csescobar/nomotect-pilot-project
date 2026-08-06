module Ui
  module Layout
    class ApplicationShellComponent < Ui::BaseComponent
      def initialize(navigation_items:, current_user: nil, breadcrumbs: [], page_title: nil, page_description: nil, account_actions: nil, html_options: {})
        @navigation_items = navigation_items
        @current_user = current_user
        @breadcrumbs = breadcrumbs
        @page_title = page_title
        @page_description = page_description
        @account_actions = account_actions
        @html_options = html_options
      end

      def call
        tag.div(**merged_html_options(class: "application-shell", data: { controller: "navigation-drawer" })) do
          safe_join([
            link_to(I18n.t("layout.skip_to_content"), "#main-content", class: "skip-link"),
            header_markup,
            tag.div(class: "application-shell__body") do
              safe_join([ sidebar_markup, main_markup ])
            end
          ])
        end
      end

      private

      def header_markup
        tag.header(class: "application-shell__header") do
          safe_join([
            tag.button("☰", type: "button", class: "navigation-toggle", aria: { label: I18n.t("layout.open_navigation"), expanded: false, controls: "application-sidebar" }, data: { navigation_drawer_target: "toggle", action: "navigation-drawer#toggle" }),
            tag.span(helpers.platform_brand_tag(css_class: "application-shell"), class: "application-shell__brand"),
            tag.div(class: "application-shell__header-actions") do
              safe_join([
                account_markup
              ].compact)
            end
          ])
        end
      end

      def sidebar_markup
        safe_join([
          tag.aside(id: "application-sidebar", class: "application-shell__sidebar", data: { navigation_drawer_target: "drawer" }) do
            safe_join([
              tag.button("×", type: "button", class: "navigation-close", aria: { label: I18n.t("layout.close_navigation") }, data: { action: "navigation-drawer#close" }),
              render(NavigationComponent.new(items: @navigation_items, label: I18n.t("layout.primary_navigation")))
            ])
          end,
          tag.button("", type: "button", class: "navigation-backdrop", aria: { label: I18n.t("layout.close_navigation") }, data: { navigation_drawer_target: "backdrop", action: "navigation-drawer#close" }, hidden: true)
        ])
      end

      def main_markup
        tag.main(id: "main-content", class: "application-shell__main", tabindex: -1) do
          safe_join([
            (render(BreadcrumbsComponent.new(items: @breadcrumbs)) if @breadcrumbs.present?),
            (render(PageHeaderComponent.new(title: @page_title, description: @page_description)) if @page_title.present?),
            content
          ].compact)
        end
      end

      def account_markup
        return unless @current_user

        label = @current_user.respond_to?(:email_address) ? @current_user.email_address : @current_user.to_s
        tag.details(class: "account-menu") do
          safe_join([
            tag.summary(class: "account-menu__summary", aria: { label: I18n.t("layout.account") }) do
              safe_join([
                tag.span(label.first.upcase, class: "account-menu__avatar", aria: { hidden: true }),
                tag.span(label, class: "application-shell__account")
              ])
            end,
            tag.div(@account_actions, class: "account-menu__panel")
          ])
        end
      end
    end
  end
end
