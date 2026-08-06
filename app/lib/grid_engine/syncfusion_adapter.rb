module GridEngine
  # Serializes grid results in the format expected by the Syncfusion EJ2 Grid
  # Custom Data Binding protocol.
  #
  # EJ2 Custom Data Binding expects:
  #   { result: [...records], count: total_count }
  #
  # Column definitions follow the EJ2 column schema:
  #   { field:, headerText:, visible:, allowSorting:, allowFiltering:, type: }
  #
  # EJ2 type values: "string", "number", "boolean", "date", "datetime"
  class SyncfusionAdapter
    # Maps GridEngine column types to EJ2 column type identifiers.
    EJ2_TYPE_MAP = {
      "string"   => "string",
      "integer"  => "number",
      "decimal"  => "number",
      "boolean"  => "boolean",
      "date"     => "date",
      "datetime" => "datetime"
    }.freeze

    def initialize(definition)
      @definition = definition
    end

    # Returns column definitions in EJ2 Grid column schema format.
    def columns
      @definition.columns.values.map do |column|
        {
          field:         column.key,
          headerText:    @definition.label_for(column),
          visible:       column.visible,
          allowSorting:  column.sortable,
          allowFiltering: column.filterable,
          type:          ej2_type_for(column.type)
        }
      end
    end

    # Serializes a result object into the EJ2 Custom Data Binding response shape.
    # @param result [#records, #total_count]
    # @return [Hash] { result: Array, count: Integer }
    def response(result)
      {
        result: result.records.map { |record| serialize_record(record) },
        count: result.total_count
      }
    end

    # Serializes distinct values for a field when EJ2 requests filter choices (action: "filterchoice")
    def filter_choice_response(result, field:)
      field_key = field.to_s
      column = @definition.columns[field_key]
      attr_name = column ? column.attribute : field_key

      distinct_values = result.records.map do |record|
        val = record.respond_to?(attr_name) ? record.public_send(attr_name) : nil
        { field_key => val, "text" => val }
      end.uniq

      {
        result: distinct_values,
        count: distinct_values.size
      }
    end

    private

    def serialize_record(record)
      @definition.columns.values.to_h do |column|
        value = record.respond_to?(column.attribute) ? record.public_send(column.attribute) : nil
        [ column.key, value ]
      end
    end

    def ej2_type_for(type)
      EJ2_TYPE_MAP.fetch(type.to_s, "string")
    end
  end
end
