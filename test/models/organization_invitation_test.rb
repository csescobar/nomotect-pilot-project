require "test_helper"

class OrganizationInvitationTest < ActiveSupport::TestCase
  setup do
    @owner = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    @invitee = User.create!(email_address: "invitee@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @membership = @organization.memberships.create!(user: @owner, role: "owner")
  end

  test "accepts a pending invitation for the matching user" do
    invitation = @organization.organization_invitations.create!(
      invited_by: @owner,
      email_address: @invitee.email_address,
      role: "admin"
    )

    assert_difference "Membership.count", 1 do
      invitation.accept!(@invitee)
    end

    assert_equal "admin", @organization.membership_for(@invitee).role
    assert invitation.reload.accepted_at.present?
  end

  test "rejects acceptance by a different email address" do
    other = User.create!(email_address: "other@example.com", password: "a-secure-password")
    invitation = @organization.organization_invitations.create!(
      invited_by: @owner,
      email_address: @invitee.email_address,
      role: "member"
    )

    assert_raises ActiveRecord::RecordInvalid do
      invitation.accept!(other)
    end
  end

  test "prevents removing the last owner" do
    assert_not @membership.destroy
    assert @membership.errors.any?
  end

  test "allows ownership change when another owner remains" do
    second_owner = User.create!(email_address: "second-owner@example.com", password: "a-secure-password")
    @organization.memberships.create!(user: second_owner, role: "owner")

    assert @membership.update(role: "admin")
  end
end
