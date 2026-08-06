require "test_helper"

class OrganizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    sign_in(@user)
  end

  test "creates an organization with the current user as owner" do
    token = csrf_token

    assert_difference [ "Organization.count", "Membership.count" ], 1 do
      post organizations_path, params: {
        authenticity_token: token,
        organization: { name: "Acme" }
      }
    end

    organization = Organization.last
    assert_redirected_to organization_path(organization)
    assert_equal "owner", organization.membership_for(@user).role
  end

  test "lists only organizations belonging to the current user" do
    visible = Organization.create!(name: "Visible")
    visible.memberships.create!(user: @user, role: "member")
    Organization.create!(name: "Hidden")

    get organizations_path

    assert_response :success
    assert_select "a", text: "Visible"
    assert_select "a", text: "Hidden", count: 0
  end

  test "forbids access to another organization's page" do
    organization = Organization.create!(name: "Private")

    get organization_path(organization)

    assert_response :forbidden
  end

  test "organization page uses concise customer and danger-zone actions" do
    organization = Organization.create!(name: "Acme")
    organization.memberships.create!(user: @user, role: "owner")

    get organization_path(organization)

    assert_response :success
    assert_select "a.button--primary", text: "View customers"
    assert_select ".ui-danger-zone", text: /Delete organization/
  end

  private

  def sign_in(user)
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: {
      authenticity_token: token,
      email_address: user.email_address,
      password: "a-secure-password"
    }
    follow_redirect!
  end

  def csrf_token
    Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
  end
end
