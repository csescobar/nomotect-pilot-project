module Ui
  class CardComponent < BaseComponent
    VARIANTS = %i[default outlined elevated].freeze
    PADDINGS = %i[none small medium large].freeze

    def initialize(variant: :default, padding: :medium, html_options: {})
      @variant = variant.to_sym
      @padding = padding.to_sym
      @html_options = html_options

      validate_option!(:variant, @variant, VARIANTS)
      validate_option!(:padding, @padding, PADDINGS)
    end

    def call
      tag.section(
        content,
        **merged_html_options(class: class_names("ui-card", "ui-card--#{@variant}", "ui-card--padding-#{@padding}"))
      )
    end
  end
end
