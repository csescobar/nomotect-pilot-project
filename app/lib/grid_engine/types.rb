module GridEngine
  module Types
    Definition = Data.define(:name, :caster, :formatter) do
      def cast(value) = caster.call(value)
      def format(value, locale: I18n.locale, context: :compact) = formatter.call(value, locale, context)
    end

    module_function

    def registry
      @registry ||= Registry.new.tap do |items|
        items.register(:string, Definition.new(name: :string, caster: ->(value) { value.to_s }, formatter: ->(value, _, _) { value.to_s }))
        items.register(:integer, Definition.new(name: :integer, caster: ->(value) { Integer(value, exception: false) }, formatter: ->(value, _, _) { value.to_i.to_s }))
        items.register(:decimal, Definition.new(name: :decimal, caster: ->(value) { BigDecimal(value.to_s, exception: false) }, formatter: ->(value, _, _) { value.to_s("F") }))
        items.register(:boolean, Definition.new(name: :boolean, caster: ->(value) { ActiveModel::Type::Boolean.new.cast(value) }, formatter: ->(value, _, _) { value ? "true" : "false" }))
        items.register(:date, Definition.new(name: :date, caster: ->(value) { Date.parse(value.to_s) rescue nil }, formatter: method(:format_date)))
        items.register(:datetime, Definition.new(name: :datetime, caster: ->(value) { Time.zone.parse(value.to_s) rescue nil }, formatter: method(:format_datetime)))
      end
    end

    def format_date(value, locale, context)
      return value.iso8601 if context == :machine

      I18n.l(value, locale: locale, format: context == :long ? :long : :short)
    end

    def format_datetime(value, locale, context)
      return value.iso8601 if context == :machine

      I18n.l(value, locale: locale, format: context == :long ? :long : :short)
    end
  end
end
