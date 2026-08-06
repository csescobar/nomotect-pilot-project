module GridEngine
  module Operators
    Definition = Data.define(:name, :arity, :predicate)

    module_function

    def registry
      @registry ||= Registry.new.tap do |items|
        items.register(:eq, Definition.new(name: :eq, arity: 1, predicate: ->(attribute, value) { attribute.eq(value) }))
        items.register(:not_eq, Definition.new(name: :not_eq, arity: 1, predicate: ->(attribute, value) { attribute.not_eq(value) }))
        items.register(:contains, Definition.new(name: :contains, arity: 1, predicate: ->(attribute, value) { attribute.matches("%#{sanitize_like(value)}%") }))
        items.register(:starts_with, Definition.new(name: :starts_with, arity: 1, predicate: ->(attribute, value) { attribute.matches("#{sanitize_like(value)}%") }))
        items.register(:gt, Definition.new(name: :gt, arity: 1, predicate: ->(attribute, value) { attribute.gt(value) }))
        items.register(:gte, Definition.new(name: :gte, arity: 1, predicate: ->(attribute, value) { attribute.gteq(value) }))
        items.register(:lt, Definition.new(name: :lt, arity: 1, predicate: ->(attribute, value) { attribute.lt(value) }))
        items.register(:lte, Definition.new(name: :lte, arity: 1, predicate: ->(attribute, value) { attribute.lteq(value) }))
        items.register(:in, Definition.new(name: :in, arity: :many, predicate: ->(attribute, value) { attribute.in(Array(value)) }))
        items.register(:blank, Definition.new(name: :blank, arity: 0, predicate: ->(attribute, _) { attribute.eq(nil).or(attribute.eq("")) }))
      end
    end

    def sanitize_like(value)
      ActiveRecord::Base.sanitize_sql_like(value.to_s)
    end
  end
end
