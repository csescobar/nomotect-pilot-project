module GridEngine
  module Catalog
    Entry = Data.define(:definition, :scope)
    KEY = /\A[a-z][a-z0-9_]*\z/

    class Registry
      def initialize
        @entries = {}
        @sealed = false
        register("organizations", definition: Definition.new(key: :organizations, model_class: Organization) do
          column :name, type: :string
          column :slug, type: :string
          column :created_at, type: :datetime
          sort :name
        end, scope: ->(user:, **) { user.organizations.distinct })
      end

      def fetch(key)
        @entries.fetch(key.to_s) { raise KeyError, "Unknown grid: #{key}" }
      end

      def register(key, definition:, scope:)
        raise RuntimeError, "grid registry is sealed" if sealed?

        key = key.to_s
        raise ArgumentError, "invalid grid key" unless KEY.match?(key)
        raise ArgumentError, "grid is already registered" if @entries.key?(key)
        raise ArgumentError, "definition key mismatch" unless definition.key == key
        raise ArgumentError, "scope must be callable" unless scope.respond_to?(:call)

        @entries[key] = Entry.new(definition, scope).freeze
      end

      def sealed? = @sealed

      def seal!
        @entries.freeze
        @sealed = true
      end
    end

    class << self
      attr_reader :registry

      def fetch(key) = registry.fetch(key).definition
      def scope_for(key, **context) = registry.fetch(key).scope.call(**context)
      def register(...) = registry.register(...)
      def seal! = registry.seal!
      def reset! = @registry = Registry.new
    end

    reset!
  end
end
