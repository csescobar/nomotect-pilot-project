# frozen_string_literal: true

module OperationalReadiness
  class DiagnosticCollectorRegistry
    ID_PATTERN = /\A[a-z][a-z0-9_]*\z/

    def initialize
      @collectors = {}
    end

    def register(id, &collector)
      id = id.to_s
      raise InvalidCollector, "diagnostic collector id is invalid" unless ID_PATTERN.match?(id)
      raise InvalidCollector, "diagnostic collector block is required" unless collector
      raise InvalidCollector, "diagnostic collector is already registered" if collectors.key?(id)

      collectors[id] = collector
      self
    end

    def collect(selected: nil)
      ids = selected ? Array(selected).map(&:to_s) : collectors.keys.sort
      unknown = ids - collectors.keys
      raise InvalidCollector, "diagnostic collector is not registered" if unknown.any?

      ids.sort.to_h do |id|
        [ id, collectors.fetch(id).call ]
      rescue StandardError
        raise CollectionFailed, "diagnostic collector failed"
      end
    end

    private

    attr_reader :collectors

    class InvalidCollector < StandardError; end
    class CollectionFailed < StandardError; end
  end
end
