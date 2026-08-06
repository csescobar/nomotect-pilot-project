module Ui
  class DividerComponent < BaseComponent
    ORIENTATIONS = %i[horizontal vertical].freeze

    def initialize(orientation: :horizontal, label: nil, html_options: {})
      @orientation = orientation.to_sym
      @label = label
      @html_options = html_options

      validate_option!(:orientation, @orientation, ORIENTATIONS)
    end

    def call
      tag.div(
        @label,
        **merged_html_options(
          class: class_names("ui-divider", "ui-divider--#{@orientation}"),
          role: "separator",
          aria: { orientation: @orientation }
        )
      )
    end
  end
end
