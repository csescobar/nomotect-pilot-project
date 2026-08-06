# frozen_string_literal: true

module OperationalReadiness
  class HealthProviderRegistry
    Provider = Data.define(:id, :category, :required, :callable)

    def initialize
      @providers = {}
    end

    def register(id, category:, required:, &provider)
      id = id.to_s
      raise InvalidProvider, "health provider id is invalid" unless id.match?(/\A[a-z][a-z0-9_.]*\z/)
      raise InvalidProvider, "health provider category is invalid" unless HealthSignal::CATEGORIES.include?(category.to_s)
      raise InvalidProvider, "health provider block is required" unless provider
      raise InvalidProvider, "health provider is already registered" if providers.key?(id)

      providers[id] = Provider.new(id:, category: category.to_s, required:, callable: provider)
      self
    end

    def all = providers.values.sort_by(&:id)

    private

    attr_reader :providers

    class InvalidProvider < StandardError; end
  end
end
