module Ui
  class LocaleSwitcherComponent < BaseComponent
    def initialize(current_locale:, action:, show_label: true, html_options: {})
      @current_locale = Localization::SupportedLocales.fetch(current_locale).code
      @action = action
      @show_label = show_label
      @html_options = html_options
    end

    def call
      form_with(url: @action, method: :patch, html: merged_html_options(class: "theme-switcher locale-switcher", data: { controller: "auto-submit" })) do |form|
        safe_join([
          (@show_label ? form.label(:locale, I18n.t("localization.label"), class: "theme-switcher__label locale-switcher__label") : nil),
          form.select(
            :locale,
            Localization::SupportedLocales.options,
            { selected: @current_locale },
            class: "theme-switcher__select locale-switcher__select",
            aria: { label: I18n.t("localization.label") },
            data: { action: "change->auto-submit#submit" }
          ),
          tag.noscript(form.submit(I18n.t("localization.apply"), class: "button button--secondary button--small"))
        ].compact)
      end
    end
  end
end
