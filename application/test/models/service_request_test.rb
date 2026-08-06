require "test_helper"

class ServiceRequestTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme")
    @requester = User.create!(email_address: "requester@example.com", password: "a-secure-password")
    @agent = User.create!(email_address: "agent@example.com", password: "a-secure-password")
    @organization.memberships.create!(user: @requester, role: "administrator")
    @organization.memberships.create!(user: @agent, role: "support_agent")
  end

  def build_request(overrides = {})
    ServiceRequest.new({
      organization: @organization,
      requester: @requester,
      identifier: "00000001",
      title: "Printer offline",
      description: "The third floor printer is offline.",
      category: "hardware",
      priority: "high",
      status: "open"
    }.merge(overrides))
  end

  def create_request(overrides = {})
    build_request(overrides).tap(&:save!)
  end

  test "validates required attributes and enumerations" do
    request = ServiceRequest.new(organization: @organization, requester: @requester)

    assert_not request.valid?
    assert request.errors[:identifier].any?
    assert request.errors[:title].any?
    assert request.errors[:description].any?
    assert request.errors[:category].any?
    assert request.errors[:priority].any?

    request = build_request(category: "bogus", priority: "urgent", status: "unknown")
    assert_not request.valid?
    assert request.errors[:category].any?
    assert request.errors[:priority].any?
    assert request.errors[:status].any?
  end

  test "identifier must be unique per organization" do
    create_request
    duplicate = build_request

    assert_not duplicate.valid?
    assert duplicate.errors[:identifier].any?

    other_org = Organization.create!(name: "Orion")
    other_org.memberships.create!(user: @requester, role: "administrator")
    same_identifier = build_request(organization: other_org)

    assert same_identifier.valid?
  end

  test "assigned agent must belong to the same organization" do
    outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")
    request = build_request(assigned_support_agent: outsider)

    assert_not request.valid?
    assert request.errors[:assigned_support_agent].any?

    request = build_request(assigned_support_agent: @agent)
    assert request.valid?
  end

  test "transition_to! advances status through valid transitions" do
    request = create_request

    assert request.open?
    request.transition_to!("triaged")
    assert request.triaged?
    assert request.transition_to!("in_progress")
    assert request.in_progress?
    request.transition_to!("resolved")
    assert request.resolved?
    assert request.resolved_at.present?
    request.transition_to!("closed")
    assert request.closed?
    assert request.closed_at.present?
  end

  test "transition_to! rejects invalid transitions" do
    request = create_request

    assert_raises(ArgumentError) { request.transition_to!("resolved") }
    assert_raises(ArgumentError) { request.transition_to!("bogus") }
    assert request.open?
  end

  test "direct status update enforces the transition map" do
    request = create_request
    request.update!(status: "in_progress")

    assert_raises(ActiveRecord::RecordInvalid) do
      request.update!(status: "closed")
    end
    assert request.reload.in_progress?
  end

  test "ordered scope sorts by identifier then id" do
    request = create_request(identifier: "00000002")
    first = create_request(identifier: "00000001")

    assert_equal [ first, request ], ServiceRequest.where(organization: @organization).ordered
  end

  test "status predicates are generated for every status" do
    request = create_request(status: "open")

    assert request.open?
    assert_not request.closed?

    request.update!(status: "triaged")
    assert request.triaged?
    assert_not request.open?
  end
end
