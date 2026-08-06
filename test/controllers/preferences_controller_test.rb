require "test_helper"

class PreferencesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "preferences@example.com", password: "a-secure-password")
  end

  test "requires authentication" do
    get preferences_path

    assert_redirected_to new_session_path
  end

  test "renders theme and locale preferences outside the application header" do
    sign_in

    get preferences_path

    assert_response :success
    assert_select "main .preferences-layout [data-controller='theme']"
    assert_select "main .preferences-layout form.locale-switcher"
    assert_select "header .theme-switcher", count: 0
    assert_select "header .locale-switcher", count: 0
    assert_select "details.account-menu a[href='#{preferences_path}']", text: "Settings"
  end

  private

  def sign_in
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: {
      authenticity_token: token,
      email_address: @user.email_address,
      password: "a-secure-password"
    }
    follow_redirect!
  end
end
