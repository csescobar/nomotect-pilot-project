require "test_helper"

class ServiceRequestPolicyTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email_address: "admin@example.com", password: "a-secure-password")
    @agent = User.create!(email_address: "agent@example.com", password: "a-secure-password")
    @requester = User.create!(email_address: "requester@example.com", password: "a-secure-password")
    @outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @admin, role: "administrator")
    @organization.memberships.create!(user: @agent, role: "support_agent")
    @organization.memberships.create!(user: @requester, role: "requester")
    @request = ServiceRequest.create!(
      organization: @organization,
      requester: @requester,
      identifier: "00000001",
      title: "VPN access",
      description: "Cannot reach the office network.",
      category: "network",
      priority: "high"
    )
  end

  def policy(user, record = @request)
    ServiceRequestPolicy.new(user, record)
  end

  test "administrator can perform every service desk action" do
    assert policy(@admin).show?
    assert policy(@admin).create?
    assert policy(@admin).update?
    assert policy(@admin).assign?
    assert policy(@admin).transition?
    assert policy(@admin).attach_file?
    assert policy(@admin).export?
    assert policy(@admin).destroy?
  end

  test "support agent can read, assign and transition but not create" do
    assert policy(@agent).show?
    assert policy(@agent).assign?
    assert policy(@agent).transition?
    assert policy(@agent).export?
    assert_not policy(@agent).create?
    assert_not policy(@agent).update?
    assert_not policy(@agent).attach_file?
    assert_not policy(@agent).destroy?
  end

  test "requester can create, read their own and attach to their own" do
    assert policy(@requester).create?
    assert policy(@requester).show?
    assert policy(@requester).attach_file?
    assert_not policy(@requester).update?
    assert_not policy(@requester).assign?
    assert_not policy(@requester).export?

    assert_not policy(@requester, ServiceRequest.new(organization: @organization, requester: @admin)).show?
    assert_not policy(@requester, ServiceRequest.new(organization: @organization, requester: @admin)).attach_file?
  end

  test "outsider is denied everything" do
    assert_not policy(@outsider).show?
    assert_not policy(@outsider).create?
    assert_not policy(@outsider).assign?
    assert_not policy(@outsider).transition?
    assert_not policy(@outsider).export?
  end
end
