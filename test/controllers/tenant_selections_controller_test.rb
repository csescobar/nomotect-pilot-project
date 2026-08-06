require "test_helper"

class TenantSelectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    suffix = SecureRandom.hex(4)
    @password = "correct horse battery staple"
    @user = User.create!(email_address: "tenant-selector-#{suffix}@example.com", password: @password)
    @first = Organization.create!(name: "First #{suffix}")
    @second = Organization.create!(name: "Second #{suffix}")
    @foreign = Organization.create!(name: "Foreign #{suffix}")
    Membership.create!(organization: @first, user: @user, role: "owner")
    Membership.create!(organization: @second, user: @user, role: "member")

    get new_session_path
    post session_path,
      params: { email_address: @user.email_address, password: @password },
      headers: csrf_headers
    assert_response :redirect
  end

  test "selects only an organization belonging to the signed-in user" do
    get root_path
    patch tenant_selection_path,
      params: { organization_id: @second.id },
      headers: csrf_headers

    assert_redirected_to organization_path(@second)
    follow_redirect!
    assert_response :success
  end

  test "rejects cross-tenant selection" do
    get root_path
    patch tenant_selection_path,
      params: { organization_id: @foreign.id },
      headers: csrf_headers

    assert_response :not_found
  end

  test "rejects a selected tenant after membership removal" do
    get root_path
    patch tenant_selection_path,
      params: { organization_id: @second.id },
      headers: csrf_headers
    assert_response :redirect

    @second.memberships.find_by!(user: @user).destroy!
    get root_path

    assert_response :not_found
  end

  private

  def csrf_headers
    token = response.body.match(/<meta name="csrf-token" content="([^"]+)"/)&.captures&.first
    raise "CSRF meta token not found in response" if token.blank?

    { "X-CSRF-Token" => token }
  end
end
