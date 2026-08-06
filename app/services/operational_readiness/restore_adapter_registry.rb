# frozen_string_literal: true

module OperationalReadiness
  class RestoreAdapterRegistry
    def initialize
      @adapters = {}
    end

    def register(provider, component, &adapter)
      raise ArgumentError, "restore adapter block is required" unless adapter

      key = [ provider.to_s, component.to_s ]
      raise DuplicateAdapter, "restore adapter is already registered" if adapters.key?(key)

      adapters[key] = adapter
      self
    end

    def restore(component:, step:, target:)
      key = [ component.fetch("provider"), component.fetch("kind") ]
      adapter = adapters.fetch(key) { raise AdapterUnavailable, "approved restore adapter is unavailable" }
      adapter.call(component:, step:, target:)
    rescue KeyError
      raise AdapterUnavailable, "approved restore adapter is unavailable"
    end

    private

    attr_reader :adapters

    class DuplicateAdapter < StandardError; end
    class AdapterUnavailable < StandardError; end
  end
end
