# frozen_string_literal: true

module Upgrades
  class OperationRegistry
    def initialize
      @handlers = {}
    end

    def register(id, &handler)
      raise ArgumentError, "operation already registered" if handlers.key?(id.to_s)
      handlers[id.to_s] = handler
      self
    end

    def execute(operation)
      handler = handlers.fetch(operation.fetch("id")) { raise UnknownOperation, "operation is not registered" }
      handler.call(operation)
    end

    private

    attr_reader :handlers

    class UnknownOperation < StandardError; end
  end
end
