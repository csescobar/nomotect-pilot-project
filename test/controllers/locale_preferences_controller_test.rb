require "test_helper"

class LocalePreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "locale@example.com", password: "a-secure-password", locale: "en", time_zone: "UTC")

    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: {
      authenticity_token: token,
      email_address: @user.email_address,
      password: "a-secure-password"
    }
    follow_redirect!
  end

  test "persists a supported locale for authenticated user" do
    token = Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
    patch locale_preference_path, params: { authenticity_token: token, locale: "pt-BR" }, headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
    assert_equal "pt-BR", @user.reload.locale
  end

  test "allows unauthenticated users to switch locale via session" do
    reset!
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]

    original_forgery_protection = LocalePreferencesController.allow_forgery_protection
    LocalePreferencesController.allow_forgery_protection = false
    begin
      patch locale_preference_path,
        params: { authenticity_token: token, locale: "pt-BR" },
        headers: { "HTTP_REFERER" => new_session_url }
    ensure
      LocalePreferencesController.allow_forgery_protection = original_forgery_protection
    end

    assert_redirected_to new_session_path
    assert_equal "pt-BR", session[:locale]
  end

  test "rejects unsupported locales" do
    token = Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
    patch locale_preference_path, params: { authenticity_token: token, locale: "invalid" }, headers: { "HTTP_REFERER" => root_url }

    assert_redirected_to root_url
    assert_equal "en", @user.reload.locale
  end
end
