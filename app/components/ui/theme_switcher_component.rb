module Ui
  class ThemeSwitcherComponent < ApplicationComponent
    OPTIONS = %w[light dark].freeze

    def initialize(show_label: true, **html_options)
      @show_label = show_label
      @html_options = html_options
    end

    def call
      tag.div(data: { controller: "theme" }, class: "theme-switcher") do
        safe_join([
          (@show_label ? tag.label(I18n.t("theme.label"), for: "theme-preference", class: "theme-switcher__label") : nil),
          tag.select(
            options_for_select(OPTIONS.map { |theme| [ I18n.t("theme.#{theme}"), theme ] }),
            id: "theme-preference",
            class: "theme-switcher__select",
            aria: { label: I18n.t("theme.label") },
            data: { theme_target: "select", action: "theme#change" }
          )
        ].compact)
      end
    end
  end
end
