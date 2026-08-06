# frozen_string_literal: true

require "test_helper"

module Upgrades
  class InstalledStateDetectorTest < ActiveSupport::TestCase
    test "detects a credential-free installed platform state without changing it" do
      context = fake(
        current_version: 20_260_727_180_000,
        migrations_status: [
          [ "up", "20260727180000", "Create widgets" ],
          [ "down", "20260727190000", "Add widget status" ]
        ]
      )
      connection = fake(database_version: "PostgreSQL 18.4", schema_migration: Object.new)
      installation_store = fake(
        read: {
          "schema_version" => 1,
          "environment" => "test",
          "state" => "completed",
          "metadata" => {}
        }
      )

      state = InstalledStateDetector.new(
        version: "0.4.0",
        environment: "test",
        installation_store: installation_store,
        connection: connection,
        migration_context: context,
        generated_artifacts_current: true,
        extension_state_provider: -> { [] },
        clock: -> { Time.iso8601("2026-07-27T22:00:00Z") }
      ).call

      assert_equal 2, state.fetch("schema_version")
      assert_equal "0.4.0", state.dig("platform", "version")
      assert_equal "18.4.0", state.dig("runtime", "postgresql")
      assert_equal "completed", state.dig("installation", "state")
      assert_equal "20260727190000", state.dig("database", "pending_migrations", 0, "version")
      assert state.dig("generated_artifacts", "current")
      assert_equal 1, state.dig("contracts", "upgrade-manifest")
      assert_nil state.dig("deployment", "contract_version")
      assert_not_includes state.to_json, "password"
    end

    test "reports unavailable database observations without raising" do
      context = Object.new
      context.define_singleton_method(:migrations_status) { raise ActiveRecord::ConnectionNotEstablished }
      installation_store = fake(read: { "schema_version" => 1, "state" => "completed" })

      state = InstalledStateDetector.new(
        version: "0.4.0",
        installation_store: installation_store,
        connection: fake(database_version: "18.0"),
        migration_context: context,
        generated_artifacts_current: true,
        extension_state_provider: -> { [] }
      ).call

      assert_not state.dig("database", "available")
      assert_equal "ActiveRecord::ConnectionNotEstablished", state.dig("database", "error")
    end

    test "uses the canonical repository version when no override is provided" do
      context = fake(current_version: 1, migrations_status: [])
      installation_store = fake(read: { "schema_version" => 1, "state" => "completed" })
      state = InstalledStateDetector.new(
        installation_store: installation_store,
        connection: fake(database_version: "18.0"),
        migration_context: context,
        generated_artifacts_current: true,
        extension_state_provider: -> { [] }
      ).call

      assert_equal Platform::Version.current.to_s, state.dig("platform", "version")
    end

    test "includes structured extension state from the extension provider" do
      context = fake(current_version: 1, migrations_status: [])
      installation_store = fake(read: { "schema_version" => 1, "state" => "completed" })
      extension_state = [
        {
          "id" => "acme.audit",
          "package" => "acme-audit",
          "version" => "1.2.0",
          "required" => true,
          "contract_version" => 1,
          "status" => "ready",
          "finding_codes" => [],
          "capabilities" => [],
          "components" => {},
          "pending_migrations" => []
        }
      ]

      state = InstalledStateDetector.new(
        installation_store: installation_store,
        connection: fake(database_version: "18.0"),
        migration_context: context,
        generated_artifacts_current: true,
        extension_state_provider: -> { extension_state }
      ).call

      assert_equal "acme.audit", state.dig("extensions", 0, "id")
      assert_equal "ready", state.dig("extensions", 0, "status")
    end

    private

    def fake(**methods)
      Object.new.tap do |object|
        methods.each { |name, value| object.define_singleton_method(name) { value } }
      end
    end
  end
end
