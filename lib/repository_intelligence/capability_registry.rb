# frozen_string_literal: true

module RepositoryIntelligence
  class CapabilityRegistry
    Capability = Data.define(:name, :description, :public_methods)

    def initialize
      @capabilities = {}
    end

    def register(name, description:, public_methods:)
      capabilities[name.to_sym] = Capability.new(
        name: name.to_sym,
        description:,
        public_methods: Array(public_methods).map(&:to_sym).freeze
      )
      self
    end

    def fetch(name)
      capabilities.fetch(name.to_sym)
    end

    def all
      capabilities.values.sort_by(&:name)
    end

    def to_h
      all.to_h do |capability|
        [ capability.name, { description: capability.description, public_methods: capability.public_methods } ]
      end
    end

    private

    attr_reader :capabilities
  end
end
