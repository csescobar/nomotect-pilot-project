# frozen_string_literal: true

require "timeout"

module RepositoryIntelligence
  class McpRequestGuard
    LimitExceeded = Class.new(StandardError)

    def initialize(max_requests: 1_000, timeout_seconds: 5, clock: Process.method(:clock_gettime))
      @max_requests = max_requests
      @timeout_seconds = timeout_seconds
      @clock = clock
      @request_count = 0
    end

    def call
      raise LimitExceeded, "MCP request budget exhausted" if request_count >= max_requests

      @request_count += 1
      started_at = monotonic_time
      result = Timeout.timeout(timeout_seconds) { yield }
      [ result, elapsed_ms(started_at) ]
    rescue Timeout::Error
      raise LimitExceeded, "MCP request exceeded #{timeout_seconds} seconds"
    end

    attr_reader :request_count

    private

    attr_reader :max_requests, :timeout_seconds, :clock

    def monotonic_time
      clock.call(Process::CLOCK_MONOTONIC)
    end

    def elapsed_ms(started_at)
      ((monotonic_time - started_at) * 1_000).round(2)
    end
  end
end
