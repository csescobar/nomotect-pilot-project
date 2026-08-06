require "test_helper"

class LocalizationHelperTest < ActionView::TestCase
  test "formats English values with US conventions" do
    I18n.with_locale(:en) do
      assert_equal "July 25, 2026", format_local_date(Date.new(2026, 7, 25))
      assert_equal "12,345.67", format_local_number(12_345.67)
      assert_equal "42.5%", format_local_percentage(42.5)
      assert_equal "$1,234.50", format_local_currency(1234.5)
    end
  end

  test "formats Brazilian Portuguese values with local conventions" do
    I18n.with_locale(:"pt-BR") do
      assert_equal "25 de julho de 2026", format_local_date(Date.new(2026, 7, 25))
      assert_equal "12.345,67", format_local_number(12_345.67)
      assert_equal "42,5%", format_local_percentage(42.5)
      assert_equal "R$ 1.234,50", format_local_currency(1234.5)
    end
  end
end
