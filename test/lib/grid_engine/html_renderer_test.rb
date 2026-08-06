require "test_helper"

class GridEngine::HtmlRendererTest < ActiveSupport::TestCase
  test "renders responsive metadata for localized grid cells" do
    definition = GridEngine::Definition.new(key: :organizations, model_class: Organization) do
      column :name
      column :created_at, type: :datetime
    end
    organization = Organization.new(
      name: "Aster Labs",
      created_at: Time.zone.parse("2026-07-21 18:30:00 UTC")
    )

    fragment = Nokogiri::HTML.fragment(
      GridEngine::HtmlRenderer.new(definition, [ organization ], locale: :"pt-BR").call.to_s
    )
    table = fragment.at_css("table")

    assert_includes table["class"], "responsive-data-table"
    assert_equal [ "Nome", "Criada em" ], table.css("tbody td").map { |cell| cell["data-label"] }
    assert_equal "21/07/2026 18:30", table.css("tbody td").last.text
  end
end
