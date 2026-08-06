module Ui
  class BadgeComponent < BaseComponent
    VARIANTS = %i[neutral primary success warning danger].freeze
    SIZES = %i[small medium].freeze

    def initialize(label:, variant: :neutral, size: :medium, html_options: {})
      @label = label
      @variant = variant.to_sym
      @size = size.to_sym
      @html_options = html_options

      validate_option!(:variant, @variant, VARIANTS)
      validate_option!(:size, @size, SIZES)
    end

    def call
      tag.span(
        @label,
        **merged_html_options(class: class_names("ui-badge", "ui-badge--#{@variant}", "ui-badge--#{@size}"))
      )
    end
  end
end
