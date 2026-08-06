# frozen_string_literal: true

require "time"

module RepositoryIntelligence
  class McpAuditLog
    Entry = Data.define(:request_id, :method, :operation, :status, :duration_ms, :timestamp, :error)

    def initialize(limit: 500, clock: Time.method(:now))
      @limit = limit
      @clock = clock
      @entries = []
    end

    def record(request_id:, method:, operation:, status:, duration_ms:, error: nil)
      entries << Entry.new(
        request_id:, method:, operation:, status:, duration_ms:,
        timestamp: clock.call.utc.iso8601, error:
      )
      entries.shift while entries.size > limit
    end

    def to_a
      entries.map(&:to_h)
    end

    private

    attr_reader :entries, :limit, :clock
  end
end
