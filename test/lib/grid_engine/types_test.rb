require "test_helper"

class GridEngine::TypesTest < ActiveSupport::TestCase
  test "formats dates compactly for grids and predictably for machines" do
    value = Date.new(2026, 7, 21)
    type = GridEngine::Types.registry.fetch(:date)

    assert_equal "07/21/2026", type.format(value, locale: :en)
    assert_equal "21/07/2026", type.format(value, locale: :"pt-BR")
    assert_equal "2026-07-21", type.format(value, locale: :en, context: :machine)
  end

  test "formats datetimes compactly while preserving machine output" do
    value = Time.zone.parse("2026-07-21 18:30:00 UTC")
    type = GridEngine::Types.registry.fetch(:datetime)

    assert_equal "07/21/2026 18:30", type.format(value, locale: :en)
    assert_equal "21/07/2026 18:30", type.format(value, locale: :"pt-BR")
    assert_equal "2026-07-21T18:30:00Z", type.format(value, locale: :en, context: :machine)
  end
end
