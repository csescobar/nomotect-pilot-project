# frozen_string_literal: true

require "test_helper"

module Epic10
  class RepresentativeApplicationJourneyTest < ActiveSupport::TestCase
    test "loads Light Dark bilingual grid saved view and export journey" do
      journey = load_journey

      assert_equal %w[light dark], journey.data.fetch("themes")
      assert_equal %w[en pt-BR], journey.data.fetch("locales").keys
      assert_equal "csv", journey.data.dig("grid", "export", "format")
      assert_predicate journey.data, :frozen?
    end

    test "rejects system theme and missing locale" do
      data = journey_data
      data["themes"] << "system"
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }

      data = journey_data
      data["locales"].delete("pt-BR")
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }
    end

    test "rejects unsupported grid operators and cross-column saved views" do
      data = journey_data
      data.dig("grid", "columns").first["operators"] << "execute"
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.dig("grid", "saved_view", "filters").first["operator"] = "contains"
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }
    end

    test "requires credential-free csv export and complete evidence" do
      data = journey_data
      data.fetch("grid").fetch("export")["credential_free"] = false
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }

      data = journey_data
      data.fetch("evidence")["export"] = "optional"
      assert_raises(RepresentativeApplicationJourney::InvalidJourney) { build(data) }
    end

    private

    def load_journey
      RepresentativeApplicationJourney.load(Rails.root.join("test/support/representative_application/design_i18n_grid.yml"))
    end

    def journey_data
      YAML.safe_load_file(Rails.root.join("test/support/representative_application/design_i18n_grid.yml"), aliases: false)
    end

    def build(data)
      RepresentativeApplicationJourney.new(data)
    end
  end
end
