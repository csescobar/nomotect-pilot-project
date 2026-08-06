# frozen_string_literal: true

require "date"
require "json"
require "pathname"
require "yaml"

module Epic9
  class Certification
    REQUIRED_GATES = %w[
      cross_cutting_contracts
      installation
      packaging
      upgrades
      releases
      extensions
      distribution
      operational_readiness
      commercial_readiness
      documentation
    ].freeze

    def initialize(repository_path:, catalog_path: nil, catalog: nil)
      @repository_path = Pathname(repository_path)
      @catalog_path = catalog_path && Pathname(catalog_path)
      @catalog = catalog
    end

    def certify
      findings = validate_catalog
      findings.concat(validate_roadmap)
      {
        schema_version: 1,
        epic: 9,
        status: findings.empty? ? "certified" : "not_certified",
        stable_release_authorized: false,
        findings: findings
      }
    rescue Psych::Exception => error
      {
        schema_version: 1,
        epic: 9,
        status: "not_certified",
        stable_release_authorized: false,
        findings: [ "certification catalog is invalid YAML: #{error.message}" ]
      }
    end

    private

    attr_reader :repository_path, :catalog_path, :catalog

    def validate_catalog
      payload = catalog || YAML.safe_load_file(catalog_path, aliases: false)
      return [ "certification catalog must be an object" ] unless payload.is_a?(Hash)

      findings = []
      findings << "schema_version must be 1" unless payload["schema_version"] == 1
      findings << "epic must be 9" unless payload["epic"] == 9
      findings << "catalog status must be certified" unless payload["status"] == "certified"
      findings << "Epic 9 must not authorize a stable release" unless payload["stable_release_authorized"] == false
      findings.concat(validate_gates(payload["gates"]))
      findings
    end

    def validate_gates(gates)
      return [ "gates must be an array" ] unless gates.is_a?(Array)

      findings = []
      ids = gates.filter_map { |gate| gate["id"] if gate.is_a?(Hash) }
      findings << "gate identifiers must be unique" unless ids.uniq == ids

      missing = REQUIRED_GATES - ids
      extra = ids - REQUIRED_GATES
      findings << "missing gates: #{missing.join(', ')}" if missing.any?
      findings << "unknown gates: #{extra.join(', ')}" if extra.any?

      gates.each_with_index do |gate, index|
        unless gate.is_a?(Hash)
          findings << "gate #{index} must be an object"
          next
        end

        id = gate["id"] || "gate #{index}"
        findings << "#{id} must be passed" unless gate["status"] == "passed"
        evidence = gate["evidence"]
        findings << "#{id} must include evidence" unless evidence.is_a?(String) && !evidence.strip.empty?
      end
      findings
    end

    def validate_roadmap
      roadmap = repository_path.join("docs/roadmap/roadmap.md").read
      section = roadmap.split("## Epic 9", 2).fetch(1).split("## Epic 10", 2).fetch(0)
      findings = []
      findings << "Epic 9 roadmap status is not complete" unless section.include?("**Status:** ✅ Complete")
      findings << "Epic 9 roadmap contains incomplete checklist items" if section.match?(/^- \[ \]/)
      findings << "Epic 9 exit criteria are not marked satisfied" unless section.include?("**Epic 9 exit criteria:** satisfied.")
      findings
    rescue Errno::ENOENT, IndexError
      [ "Epic 9 roadmap section is missing" ]
    end
  end
end
