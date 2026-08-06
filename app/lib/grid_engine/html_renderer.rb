module GridEngine
  class HtmlRenderer
    include ActionView::Helpers::TagHelper
    include ActionView::Helpers::OutputSafetyHelper

    def initialize(definition, records, locale: I18n.locale, columns: nil)
      @definition = definition
      @records = records
      @locale = locale
      @column_keys = Array(columns).map(&:to_s).presence
    end

    def call
      tag.div(class: "grid-engine-table-wrap", tabindex: 0) do
        tag.table(class: "grid-engine-table responsive-data-table") do
          safe_join([
            tag.thead { tag.tr { safe_join(visible_columns.map { |column| tag.th(label_for(column), scope: "col") }) } },
            tag.tbody { safe_join(@records.map { |record| row(record) }) }
          ])
        end
      end
    end

    private

    def row(record)
      tag.tr do
        safe_join(visible_columns.map do |column|
          value = record.public_send(column.attribute)
          formatted = value.nil? ? "" : Types.registry.fetch(column.type).format(value, locale: @locale)
          tag.td(formatted, data: { label: label_for(column) })
        end)
      end
    end

    def visible_columns
      defaults = @definition.columns.values.select(&:visible)
      return defaults unless @column_keys

      @column_keys.filter_map { |key| @definition.columns[key] }.uniq
    end

    def label_for(column)
      @definition.label_for(column, locale: @locale)
    end
  end
end
