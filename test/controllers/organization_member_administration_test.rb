require "test_helper"

class OrganizationMemberAdministrationTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    @admin = User.create!(email_address: "admin@example.com", password: "a-secure-password")
    @member = User.create!(email_address: "member@example.com", password: "a-secure-password")
    @invitee = User.create!(email_address: "invitee@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @owner_membership = @organization.memberships.create!(user: @owner, role: "owner")
    @admin_membership = @organization.memberships.create!(user: @admin, role: "admin")
    @member_membership = @organization.memberships.create!(user: @member, role: "member")
  end

  test "administrator creates a pending invitation" do
    sign_in(@admin)

    assert_difference "OrganizationInvitation.pending.count", 1 do
      post organization_organization_invitations_path(@organization), params: {
        authenticity_token: csrf_token,
        organization_invitation: { email_address: @invitee.email_address, role: "member" }
      }
    end

    assert_redirected_to organization_path(@organization)
  end

  test "invited user accepts invitation" do
    invitation = @organization.organization_invitations.create!(
      invited_by: @owner,
      email_address: @invitee.email_address,
      role: "member"
    )
    sign_in(@invitee)

    patch accept_organization_invitation_path(invitation.acceptance_token), params: {
      authenticity_token: csrf_token
    }

    assert_redirected_to organization_path(@organization)
    assert_equal "member", @organization.membership_for(@invitee).role
  end

  test "administrator changes a regular member role" do
    sign_in(@admin)

    patch organization_membership_path(@organization, @member_membership), params: {
      authenticity_token: csrf_token,
      membership: { role: "admin" }
    }

    assert_redirected_to organization_path(@organization)
    assert_equal "admin", @member_membership.reload.role
  end

  test "administrator cannot change an owner" do
    sign_in(@admin)

    patch organization_membership_path(@organization, @owner_membership), params: {
      authenticity_token: csrf_token,
      membership: { role: "member" }
    }

    assert_response :forbidden
    assert_equal "owner", @owner_membership.reload.role
  end

  test "regular member cannot create invitations" do
    sign_in(@member)

    assert_no_difference "OrganizationInvitation.count" do
      post organization_organization_invitations_path(@organization), params: {
        authenticity_token: csrf_token,
        organization_invitation: { email_address: @invitee.email_address, role: "member" }
      }
    end

    assert_response :forbidden
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
