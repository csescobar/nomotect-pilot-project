require "test_helper"

class DashboardsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "dash_user@example.com", password: "a-secure-password")
    @org = Organization.create!(name: "Test Org")
    Membership.create!(user: @user, organization: @org, role: "owner")
  end

  test "authenticated user can access dashboard" do
    get new_session_path
    authenticity_token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]

    post session_path, params: {
      authenticity_token: authenticity_token,
      email_address: "dash_user@example.com",
      password: "a-secure-password"
    }

    get dashboard_path

    assert_response :success
    assert_select "h1", text: /Rails Hotwire Platform is running|NomoTect Application Home/
  end

  test "authentication redirects to dashboard by default" do
    get new_session_path
    authenticity_token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]

    post session_path, params: {
      authenticity_token: authenticity_token,
      email_address: "dash_user@example.com",
      password: "a-secure-password"
    }

    assert_redirected_to root_url
  end
end
