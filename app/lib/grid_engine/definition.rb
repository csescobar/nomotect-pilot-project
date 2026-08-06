module GridEngine
  class Definition
    Column = Data.define(:key, :attribute, :type, :label, :sortable, :filterable, :visible)

    attr_reader :key, :model_class, :columns, :default_sort

    def initialize(key:, model_class:, &block)
      @key = key.to_s
      @model_class = model_class
      @columns = {}
      @default_sort = []
      instance_eval(&block) if block
      freeze_definition
    end

    def column(key, attribute: key, type: :string, label: nil, sortable: true, filterable: true, visible: true)
      Types.registry.fetch(type)
      @columns[key.to_s] = Column.new(
        key: key.to_s,
        attribute: attribute.to_s,
        type: type.to_s,
        label: label,
        sortable: sortable,
        filterable: filterable,
        visible: visible
      )
    end

    def sort(key, direction: :asc)
      @default_sort << [ key.to_s, direction.to_s ]
    end

    def fetch_column(key)
      @columns.fetch(key.to_s) { raise KeyError, "Unknown grid column: #{key}" }
    end

    def label_for(column, locale: I18n.locale)
      column.label.presence || I18n.t("grid_engine.#{key}.columns.#{column.key}", locale: locale, default: column.key.humanize)
    end

    private

    def freeze_definition
      @columns.freeze
      @default_sort.freeze
    end
  end
end
