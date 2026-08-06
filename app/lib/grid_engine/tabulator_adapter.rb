module GridEngine
  class TabulatorAdapter
    def initialize(definition)
      @definition = definition
    end

    def columns
      @definition.columns.values.map do |column|
        {
          title: @definition.label_for(column),
          field: column.key,
          visible: column.visible,
          headerSort: column.sortable,
          headerFilter: column.filterable,
          sorter: sorter_for(column.type)
        }
      end
    end

    def response(result)
      {
        data: result.records.map { |record| serialize_record(record) },
        last_page: (result.total_count.to_f / result.per_page).ceil,
        total_count: result.total_count
      }
    end

    private

    def serialize_record(record)
      @definition.columns.values.to_h do |column|
        value = record.public_send(column.attribute)
        [ column.key, value ]
      end
    end

    def sorter_for(type)
      { "integer" => "number", "decimal" => "number", "date" => "date", "datetime" => "datetime" }.fetch(type, "string")
    end
  end
end
