require "csv"

module GridEngine
  class CsvExporter
    MAX_ROWS = 10_000

    def initialize(definition, locale: I18n.locale)
      @definition = definition
      @locale = locale
    end

    def call(scope, columns: nil)
      selected = selected_columns(columns)
      CSV.generate(headers: true) do |csv|
        csv << selected.map { |column| @definition.label_for(column, locale: @locale) }
        scope.limit(MAX_ROWS).find_each do |record|
          csv << selected.map { |column| format(record.public_send(column.attribute), column) }
        end
      end
    end

    private

    def selected_columns(keys)
      allowed = @definition.columns.values
      return allowed.select(&:visible) if keys.blank?

      Array(keys).filter_map { |key| @definition.columns[key.to_s] }.uniq
    end

    def format(value, column)
      return "" if value.nil?

      Types.registry.fetch(column.type).format(value, locale: @locale, context: :machine)
    end
  end
end
