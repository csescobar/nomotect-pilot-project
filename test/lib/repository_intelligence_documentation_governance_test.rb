# frozen_string_literal: true

require "test_helper"
require_relative "../../lib/repository_intelligence/documentation_governance"
require_relative "../../lib/repository_intelligence/platform"

class RepositoryIntelligenceDocumentationGovernanceTest < ActiveSupport::TestCase
  def setup
    @contracts = [
      { "id" => "platform" },
      { "id" => "operational_readiness" }
    ]
    @entry = {
      "path" => "README.md",
      "owners" => [ "@csescobar" ],
      "review_by" => "2027-01-31",
      "contracts" => [ "platform" ],
      "source_paths" => [ "config/ai/contracts/platform.yml" ]
    }
  end

  test "accepts owned fresh documentation connected to known contracts and sources" do
    governance = build([ @entry ])

    assert_empty governance.validate
  end

  test "rejects stale documents unknown contracts and missing sources" do
    invalid = @entry.merge(
      "review_by" => "2026-07-30",
      "contracts" => [ "unknown" ],
      "source_paths" => [ "missing.yml" ]
    )

    findings = build([ invalid ]).validate

    assert findings.any? { |finding| finding.include?("review is stale") }
    assert findings.any? { |finding| finding.include?("unknown contract") }
    assert findings.any? { |finding| finding.include?("source path is missing") }
  end

  test "rejects duplicate paths missing owners and path traversal" do
    invalid = @entry.merge("path" => "../README.md", "owners" => [])

    findings = build([ invalid, invalid ]).validate

    assert findings.any? { |finding| finding.include?("bounded relative path") }
    assert findings.any? { |finding| finding.include?("GitHub owner") }
    assert_includes findings, "documentation catalog paths must be unique"
  end

  test "rejects unsupported catalog schema versions" do
    governance = RepositoryIntelligence::DocumentationGovernance.new(
      repository_path: Rails.root,
      contracts: @contracts,
      catalog: { "schema_version" => 2, "documents" => [ @entry ] },
      today: Date.new(2026, 7, 31)
    )

    assert_equal [ "documentation catalog schema_version must be 1" ], governance.validate
  end

  test "certifies the repository documentation catalog" do
    governance = RepositoryIntelligence::DocumentationGovernance.new(
      repository_path: Rails.root,
      contracts: RepositoryIntelligence::ContractRegistry.new(Rails.root.join("config/ai/contracts")).load,
      catalog_path: Rails.root.join("config/ai/documentation.yml"),
      today: Date.new(2026, 7, 31)
    )

    assert_empty governance.validate
  end

  private

  def build(entries)
    RepositoryIntelligence::DocumentationGovernance.new(
      repository_path: Rails.root,
      contracts: @contracts,
      catalog: { "schema_version" => 1, "documents" => entries },
      today: Date.new(2026, 7, 31)
    )
  end
end
