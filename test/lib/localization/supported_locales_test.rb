require "test_helper"

class Localization::SupportedLocalesTest < ActiveSupport::TestCase
  test "exposes stable locale metadata" do
    assert_equal %w[en pt-BR], Localization::SupportedLocales.codes
    assert_equal "USD", Localization::SupportedLocales.fetch("en").currency
    assert_equal "BRL", Localization::SupportedLocales.fetch("pt-BR").currency
    assert_equal "America/Sao_Paulo", Localization::SupportedLocales.fetch("pt-BR").time_zone
  end

  test "falls back to the default locale for unsupported values" do
    assert_equal Localization::SupportedLocales.default, Localization::SupportedLocales.fetch("unsupported")
    assert_not Localization::SupportedLocales.include?("unsupported")
  end
end
