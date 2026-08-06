# frozen_string_literal: true

require "test_helper"

module Epic10
  class RepresentativeApplicationTest < ActiveSupport::TestCase
    test "loads deterministic bilingual and multi-tenant foundation" do
      application = load_application

      assert_equal 2, application.foundation.fetch("tenants").size
      assert_equal %w[en pt-BR], application.foundation.fetch("tenants").pluck("locale")
      assert_equal %w[light dark], application.foundation.fetch("tenants").pluck("theme")
      assert_predicate application.foundation, :frozen?
    end

    test "rejects cross-tenant assignment" do
      foundation = foundation_data
      foundation.fetch("service_requests").first["assignee_id"] = "aurora_owner"

      error = assert_raises(RepresentativeApplication::InvalidFoundation) { build(foundation) }
      assert_includes error.message, "cross-tenant assignment"
    end

    test "rejects forbidden and undocumented dependencies" do
      foundation = foundation_data
      foundation["dependencies"] << "automatic_telemetry"
      assert_raises(RepresentativeApplication::InvalidFoundation) { build(foundation) }

      foundation = foundation_data
      foundation["dependencies"] << "private_shortcut"
      assert_raises(RepresentativeApplication::InvalidFoundation) { build(foundation) }
    end

    test "rejects incomplete or secret-bearing evidence declarations" do
      foundation = foundation_data
      foundation.fetch("evidence")["credential_free"] = false

      error = assert_raises(RepresentativeApplication::InvalidFoundation) { build(foundation) }
      assert_includes error.message, "credential free"

      foundation = foundation_data
      foundation.fetch("evidence")["secret"] = "not-allowed"
      assert_raises(RepresentativeApplication::InvalidFoundation) { build(foundation) }
    end

    private

    def load_application
      RepresentativeApplication.load(
        architecture_path: Rails.root.join("config/epic_10/representative-application.yml"),
        foundation_path: Rails.root.join("test/support/representative_application/foundation.yml")
      )
    end

    def architecture_data
      YAML.safe_load_file(Rails.root.join("config/epic_10/representative-application.yml"), aliases: false)
    end

    def foundation_data
      YAML.safe_load_file(Rails.root.join("test/support/representative_application/foundation.yml"), aliases: false)
    end

    def build(foundation)
      RepresentativeApplication.new(architecture: architecture_data, foundation: foundation)
    end
  end
end
