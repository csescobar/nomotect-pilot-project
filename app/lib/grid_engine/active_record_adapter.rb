module GridEngine
  class ActiveRecordAdapter
    Result = Data.define(:records, :total_count, :page, :per_page)

    def initialize(definition)
      @definition = definition
    end

    def call(ast, scope: @definition.model_class.all)
      filtered = apply_filters(scope, ast.filters)
      ordered = apply_sorts(filtered, ast.sorts)
      total_count = filtered.count
      records = ordered.offset((ast.page - 1) * ast.per_page).limit(ast.per_page)
      Result.new(records: records, total_count: total_count, page: ast.page, per_page: ast.per_page)
    end

    private

    def apply_filters(scope, filters)
      filters.reduce(scope) do |relation, filter|
        column = @definition.fetch_column(filter.column)
        attribute = @definition.model_class.arel_table[column.attribute]
        operator = Operators.registry.fetch(filter.operator)
        relation.where(operator.predicate.call(attribute, filter.value))
      end
    end

    def apply_sorts(scope, sorts)
      sorts.reduce(scope) do |relation, sort|
        column = @definition.fetch_column(sort.column)
        attribute = @definition.model_class.arel_table[column.attribute]
        relation.order(sort.direction == "desc" ? attribute.desc : attribute.asc)
      end
    end
  end
end
