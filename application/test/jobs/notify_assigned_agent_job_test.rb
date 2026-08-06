require "test_helper"

class NotifyAssignedAgentJobTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email_address: "admin@example.com", password: "a-secure-password")
    @agent = User.create!(email_address: "agent@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @admin, role: "administrator")
    @organization.memberships.create!(user: @agent, role: "support_agent")
    @request = ServiceRequest.create!(
      organization: @organization,
      requester: @admin,
      identifier: "00000001",
      title: "VPN access",
      description: "Cannot reach the office network.",
      category: "network",
      priority: "high",
      assigned_support_agent: @agent
    )
  end

  test "notifies the assigned agent once through idempotent execution" do
    assert_difference "Notification.count", 1 do
      NotifyAssignedAgentJob.new.perform(@organization.id, @request.id, @admin.id)
    end

    notification = Notification.last
    assert_equal "service_request.assigned", notification.kind
    assert_equal @agent.id, notification.recipient_id
    assert_equal @request.identifier, notification.payload["identifier"]

    assert_no_difference "Notification.count" do
      NotifyAssignedAgentJob.new.perform(@organization.id, @request.id, @admin.id)
    end
  end

  test "raises a tenant violation for an actor outside the organization" do
    outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")

    assert_raises(TenantBoundary::Violation) do
      NotifyAssignedAgentJob.new.perform(@organization.id, @request.id, outsider.id)
    end
  end

  test "raises when the service request belongs to another organization" do
    other = Organization.create!(name: "Orion")
    other.memberships.create!(user: @admin, role: "administrator")
    foreign = ServiceRequest.create!(
      organization: other,
      requester: @admin,
      identifier: "00000001",
      title: "Foreign",
      description: "belongs elsewhere",
      category: "other",
      priority: "low"
    )

    assert_raises(ActiveRecord::RecordNotFound) do
      NotifyAssignedAgentJob.new.perform(@organization.id, foreign.id, @admin.id)
    end
  end

  test "is a no-op when no agent is assigned" do
    unassigned = ServiceRequest.create!(
      organization: @organization,
      requester: @admin,
      identifier: "00000002",
      title: "Unassigned",
      description: "no one owns this",
      category: "other",
      priority: "low"
    )

    assert_no_difference "Notification.count" do
      NotifyAssignedAgentJob.new.perform(@organization.id, unassigned.id, @admin.id)
    end
  end
end
