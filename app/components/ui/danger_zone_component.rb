module Ui
  class DangerZoneComponent < Ui::BaseComponent
    def initialize(id:, title:, description: nil, html_options: {})
      @id = id
      @title = title
      @description = description
      @html_options = html_options
    end

    def call
      tag.section(**merged_html_options(class: "ui-danger-zone", aria: { labelledby: "#{@id}-title" })) do
        safe_join([
          tag.div(class: "ui-danger-zone__copy") do
            safe_join([
              tag.h2(@title, id: "#{@id}-title", class: "ui-danger-zone__title"),
              (tag.p(@description, class: "ui-danger-zone__description") if @description.present?)
            ].compact)
          end,
          (tag.div(content, class: "ui-danger-zone__actions") if content.present?)
        ].compact)
      end
    end
  end
end
