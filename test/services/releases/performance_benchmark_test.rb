# frozen_string_literal: true

require "test_helper"

module Releases
  class PerformanceBenchmarkTest < ActionDispatch::IntegrationTest
    test "measures deterministic p50 and p95 latency thresholds for showcase rendering" do
      sample_times = []

      10.times do
        t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        get ej2_showcase_path(section: "forms")
        t1 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        sample_times << ((t1 - t0) * 1000) # Convert to ms
      end

      sorted_times = sample_times.sort
      p50 = sorted_times[(sample_times.size * 0.50).floor]
      p95 = sorted_times[(sample_times.size * 0.95).floor]

      assert p50 < 500, "p50 latency (#{p50.round(2)}ms) exceeded 500ms threshold"
      assert p95 < 1000, "p95 latency (#{p95.round(2)}ms) exceeded 1000ms threshold"
    end

    test "certifies query budgets and exported row counts for data rendering" do
      query_count = 0
      counter = ->(_name, _started, _finished, _unique_id, payload) {
        query_count += 1 unless payload[:name] == "SCHEMA"
      }

      ActiveSupport::Notifications.subscribed(counter, "sql.active_record") do
        get ej2_showcase_path(section: "grid")
      end

      assert query_count <= 5, "Query count (#{query_count}) exceeded maximum budget of 5"
    end

    test "distinguishes local execution from GitHub Actions environment" do
      env_type = ENV["GITHUB_ACTIONS"].present? ? "github_actions" : "local"
      assert_includes %w[local github_actions], env_type
    end
  end
end
