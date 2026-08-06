module Ui
  class AlertComponent < BaseComponent
    VARIANTS = %i[info success warning danger].freeze

    def initialize(title: nil, variant: :info, html_options: {})
      @title = title
      @variant = variant.to_sym
      @html_options = html_options

      validate_option!(:variant, @variant, VARIANTS)
    end

    def call
      tag.div(**merged_html_options(class: class_names("ui-alert", "ui-alert--#{@variant}"), role: role)) do
        safe_join([
          (@title.present? ? tag.strong(@title, class: "ui-alert__title") : nil),
          tag.div(content, class: "ui-alert__body")
        ].compact)
      end
    end

    private

    def role
      @variant == :danger ? "alert" : "status"
    end
  end
end
