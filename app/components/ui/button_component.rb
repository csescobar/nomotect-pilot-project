module Ui
  class ButtonComponent < BaseComponent
    VARIANTS = %i[primary secondary danger ghost].freeze
    SIZES = %i[small medium large].freeze

    def initialize(label:, href: nil, variant: :primary, size: :medium, type: :button, disabled: false, html_options: {})
      @label = label
      @href = href
      @variant = variant.to_sym
      @size = size.to_sym
      @type = type
      @disabled = disabled
      @html_options = html_options

      validate_option!(:variant, @variant, VARIANTS)
      validate_option!(:size, @size, SIZES)
    end

    def call
      options = merged_html_options(
        class: class_names("button", "button--#{@variant}", "button--#{@size}"),
        aria: { disabled: @disabled }
      )

      if @href
        options[:tabindex] = -1 if @disabled
        link_to(@label, @disabled ? nil : @href, options)
      else
        tag.button(@label, **options.merge(type: @type, disabled: @disabled))
      end
    end
  end
end
