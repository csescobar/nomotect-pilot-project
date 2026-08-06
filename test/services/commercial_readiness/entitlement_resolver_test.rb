# frozen_string_literal: true

require "test_helper"

module CommercialReadiness
  class EntitlementResolverTest < ActiveSupport::TestCase
    test "community capabilities remain available without a provider" do
      edition = EditionManifest.new(YAML.safe_load_file(Rails.root.join("config/editions/community.yml")))
      resolver = EntitlementResolver.new(edition:)

      EditionManifest::COMMUNITY_CAPABILITIES.each do |capability|
        assert_equal "available", resolver.resolve(capability).status
      end
      assert_equal "unavailable", resolver.resolve("commercial_support").status
    end

    test "provider failure never disables community capabilities or grants unknown ones" do
      edition = EditionManifest.new(YAML.safe_load_file(Rails.root.join("config/editions/community.yml")))
      resolver = EntitlementResolver.new(edition:, provider: ->(_) { raise "unavailable" })

      assert_equal "available", resolver.resolve("installation").status
      assert_equal "unavailable", resolver.resolve("commercial_support").status
    end
  end
end
