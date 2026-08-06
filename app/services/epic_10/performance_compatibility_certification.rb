# frozen_string_literal: true

require "yaml"

module Epic10
  class PerformanceCompatibilityCertification
    class InvalidCertification < StandardError; end
    METRICS = %w[request_p95_ms query_count_max render_p95_ms job_p95_ms export_1000_rows_ms].freeze
    MATRIX = %w[ruby rails postgresql browsers containers deployment].freeze

    def initialize(source_commit:, path: Rails.root.join("config/epic_10/performance-compatibility.yml"))
      @source_commit = String(source_commit)
      @path = Pathname(path)
    end

    def call
      raise InvalidCertification, "source commit must be a full lowercase SHA" unless /\A[0-9a-f]{40}\z/.match?(source_commit)
      data = YAML.safe_load_file(path, aliases: false)
      measurements, budgets = data.fetch("measurements"), data.fetch("budgets")
      breaches = METRICS.filter_map { |metric| metric if measurements.fetch(metric) > budgets.fetch(metric) }
      raise InvalidCertification, "performance budget breached: #{breaches.join(", ")}" if breaches.any?
      matrix = data.fetch("matrix")
      raise InvalidCertification, "compatibility matrix is incomplete" unless MATRIX.all? { |key| Array(matrix[key]).any? }
      environment = data.fetch("environment")
      raise InvalidCertification, "measurement environment is incomplete" unless environment["deterministic"] == true && environment["credential_free"] == true && environment["source_commit_required"] == true
      raise InvalidCertification, "certification cannot publish" unless data.dig("publication", "allowed") == false

      {
        "schema_version" => 1, "phase" => 6, "status" => "passed",
        "source_commit" => source_commit,
        "measurements" => METRICS.map { |metric| { "id" => metric, "observed" => measurements.fetch(metric), "budget" => budgets.fetch(metric), "status" => "passed" } },
        "matrix" => matrix, "environment" => environment,
        "findings" => data.fetch("findings"), "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :source_commit, :path
  end
end
