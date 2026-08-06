module GridEngine
  module Query
    Filter = Data.define(:column, :operator, :value)
    Sort = Data.define(:column, :direction)
    Ast = Data.define(:filters, :sorts, :page, :per_page) do
      def initialize(filters: [], sorts: [], page: 1, per_page: 25)
        super(filters: filters.freeze, sorts: sorts.freeze, page: page, per_page: per_page)
      end
    end

    class ValidationError < StandardError; end

    class Parser
      MAX_PER_PAGE = 250

      def initialize(definition)
        @definition = definition
      end

      def parse(params)
        Ast.new(
          filters: parse_filters(params[:filters]),
          sorts: parse_sorts(params[:sorts]),
          page: positive_integer(params[:page], default: 1),
          per_page: [ positive_integer(params[:per_page], default: 25), MAX_PER_PAGE ].min
        )
      end

      private

      def parse_filters(raw_filters)
        Array(raw_filters).map do |raw|
          column = @definition.fetch_column(raw[:column] || raw["column"])
          raise ValidationError, "Column is not filterable: #{column.key}" unless column.filterable

          operator = Operators.registry.fetch(raw[:operator] || raw["operator"])
          value = raw[:value] || raw["value"]
          cast_value = cast_filter_value(column, operator, value)
          Filter.new(column: column.key, operator: operator.name.to_s, value: cast_value)
        rescue KeyError, Registry::UnknownKeyError => error
          raise ValidationError, error.message
        end
      end

      def parse_sorts(raw_sorts)
        source = Array(raw_sorts).presence || @definition.default_sort.map { |column, direction| { column: column, direction: direction } }
        source.map do |raw|
          column = @definition.fetch_column(raw[:column] || raw["column"])
          raise ValidationError, "Column is not sortable: #{column.key}" unless column.sortable

          direction = (raw[:direction] || raw["direction"] || "asc").to_s
          raise ValidationError, "Invalid sort direction" unless direction.in?(%w[asc desc])

          Sort.new(column: column.key, direction: direction)
        end
      end

      def cast_filter_value(column, operator, value)
        return nil if operator.arity == 0

        type = Types.registry.fetch(column.type)
        operator.arity == :many ? Array(value).map { |item| type.cast(item) } : type.cast(value)
      end

      def positive_integer(value, default:)
        parsed = Integer(value, exception: false)
        parsed&.positive? ? parsed : default
      end
    end
  end
end
