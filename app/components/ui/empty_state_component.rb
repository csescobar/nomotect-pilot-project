module Ui
  class EmptyStateComponent < BaseComponent
    def initialize(title:, description: nil, html_options: {})
      @title = title
      @description = description
      @html_options = html_options
    end

    def call
      tag.section(**merged_html_options(class: "ui-empty-state", aria: { labelledby: title_id })) do
        safe_join([
          tag.h2(@title, id: title_id, class: "ui-empty-state__title"),
          (@description.present? ? tag.p(@description, class: "ui-empty-state__description") : nil),
          (content.present? ? tag.div(content, class: "ui-empty-state__actions") : nil)
        ].compact)
      end
    end

    private

    def title_id
      @title_id ||= "empty-state-#{object_id}"
    end
  end
end
