# frozen_string_literal: true

require "test_helper"

module Upgrades
  class PostUpgradeVerifierTest < ActiveSupport::TestCase
    test "regenerates verifies and records digest-bound history" do
      Dir.mktmpdir do |directory|
        regenerated = 0
        history = HistoryStore.new(path: File.join(directory, "history.json"))
        verifier = PostUpgradeVerifier.new(
          manifest: manifest,
          execution_state: execution_state,
          detector: fake(call: installed_state),
          artifact_regenerator: -> { regenerated += 1 },
          health_check: -> { true },
          history: history,
          clock: -> { Time.iso8601("2026-07-28T00:00:00Z") }
        )

        record = verifier.verify_and_record!

        assert_equal 1, regenerated
        assert_equal ManifestDigest.call(manifest), record.fetch("manifest_digest")
        assert_equal "completed", record.fetch("status")
        assert_equal %w[migrate regenerate], record.fetch("operations").pluck("id")
        assert history.completed_digest?(record.fetch("manifest_digest"))
        assert_raises(HistoryStore::ReplayDetected) { verifier.verify_and_record! }
        assert_equal 1, regenerated
      end
    end

    test "does not record history when verification fails" do
      Dir.mktmpdir do |directory|
        state = installed_state
        state["database"]["pending_migrations"] = [ { "version" => "2", "name" => "Pending" } ]
        history = HistoryStore.new(path: File.join(directory, "history.json"))
        verifier = PostUpgradeVerifier.new(
          manifest: manifest,
          execution_state: execution_state,
          detector: fake(call: state),
          artifact_regenerator: -> { },
          health_check: -> { true },
          history: history
        )

        error = assert_raises(PostUpgradeVerifier::VerificationFailed) { verifier.verify_and_record! }
        assert_includes error.findings.pluck(:code), "database_schema_unverified"
        assert_empty history.records
      end
    end

    private

    def fake(**methods)
      Object.new.tap { |object| methods.each { |name, value| object.define_singleton_method(name) { value } } }
    end

    def execution_state
      {
        "manifest_id" => "upgrade-0-5", "source_version" => "0.4.0", "target_version" => "0.5.0",
        "status" => "completed", "started_at" => "2026-07-27T23:00:00Z",
        "operations" => [
          { "id" => "migrate", "status" => "completed" },
          { "id" => "regenerate", "status" => "completed" }
        ]
      }
    end

    def installed_state
      {
        "platform" => { "version" => "0.5.0" },
        "runtime" => {},
        "contracts" => { "installation-state" => 1, "upgrade-history" => 1 },
        "installation" => { "state" => "completed", "contract_version" => 1 },
        "deployment" => { "contract_version" => nil },
        "database" => { "available" => true, "schema_version" => "20260728000000", "pending_migrations" => [] },
        "generated_artifacts" => { "current" => true }
      }
    end

    def manifest
      @manifest ||= Manifest.new(
        "schema_version" => 1,
        "id" => "upgrade-0-5",
        "source" => { "requirement" => ">= 0.4.0, < 0.5.0" },
        "target" => { "version" => "0.5.0" },
        "compatibility" => {
          "rails" => "~> 8.1.0", "ruby" => "~> 4.0.0", "postgresql" => "~> 18.0",
          "contracts" => { "installation-state" => 1, "upgrade-history" => 1 }
        },
        "backup" => { "required" => true, "evidence" => %w[database persistent_files] },
        "operations" => [
          { "id" => "migrate", "type" => "database", "description" => "Migrate", "reversible" => false, "requires" => [] }
        ],
        "deprecations" => []
      )
    end
  end
end
