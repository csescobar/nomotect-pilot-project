require "test_helper"

class UserLocalizationTest < ActiveSupport::TestCase
  test "applies defaults when preferences are blank" do
    user = User.new(email_address: "defaults@example.com", password: "a-secure-password", locale: nil, time_zone: nil)

    assert user.valid?
    assert_equal Localization::SupportedLocales.default.code, user.locale
    assert_equal Localization::SupportedLocales.default.time_zone, user.time_zone
  end

  test "rejects unsupported localization preferences" do
    user = User.new(email_address: "invalid@example.com", password: "a-secure-password", locale: "invalid", time_zone: "Nowhere/Unknown")

    assert_not user.valid?
    assert user.errors.added?(:locale, :inclusion, value: "invalid")
    assert user.errors.added?(:time_zone, :invalid)
  end
end
