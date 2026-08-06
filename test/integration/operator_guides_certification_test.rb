# frozen_string_literal: true

require "test_helper"

class OperatorGuidesCertificationTest < ActiveSupport::TestCase
  HANDBOOK = Rails.root.join("docs/operators/handbook.md")
  REQUIRED_SECTIONS = [
    "Administrator guide",
    "Installation guide",
    "Deployment guide",
    "Upgrade guide",
    "Recovery guide",
    "Extension guide",
    "Release and distribution operations",
    "Routine operator checklist",
    "Escalation evidence"
  ].freeze
  REQUIRED_TARGETS = [
    "README.md",
    "docs/installation/architecture.md",
    "docs/deployment/private-vps.md",
    "docs/deployment/kamal.md",
    "docs/deployment/render.md",
    "docs/upgrades/architecture.md",
    "docs/upgrades/recovery-and-certification.md",
    "docs/operations/disaster-recovery.md",
    "docs/operations/resilience-certification.md",
    "docs/extensions/lifecycle-guide.md",
    "docs/governance/release-process.md",
    "docs/distribution/operations.md"
  ].freeze

  test "publishes every required operator workflow from one supported entry point" do
    content = HANDBOOK.read

    REQUIRED_SECTIONS.each do |section|
      assert_includes content, "## #{section}"
    end
  end

  test "keeps every canonical guide target present" do
    REQUIRED_TARGETS.each do |target|
      assert Rails.root.join(target).file?, "missing operator guide target: #{target}"
    end
  end

  test "states the credential, approval and recovery safety boundaries" do
    content = HANDBOOK.read
    normalized = content.downcase.gsub(/\s+/, " ")

    assert_includes normalized, "never place credentials"
    assert_includes content, "human approval before return to service"
    assert_includes content, "Never treat a successful backup as proof of restore"
    assert_includes content, "Never attach raw secrets"
  end
end
