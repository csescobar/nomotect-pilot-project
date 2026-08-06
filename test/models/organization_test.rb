require "test_helper"

class OrganizationTest < ActiveSupport::TestCase
  test "assigns a unique slug" do
    first = Organization.create!(name: "Example Team")
    second = Organization.create!(name: "Example Team")

    assert_equal "example-team", first.slug
    assert_equal "example-team-2", second.slug
  end

  test "finds a user's membership" do
    user = User.create!(email_address: "member@example.com", password: "a-secure-password")
    organization = Organization.create!(name: "Example")
    membership = organization.memberships.create!(user: user, role: "owner")

    assert_equal membership, organization.membership_for(user)
  end
end
