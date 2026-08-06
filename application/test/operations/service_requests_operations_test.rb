require "test_helper"

class ServiceRequestsOperationsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    @agent = User.create!(email_address: "agent@example.com", password: "a-secure-password")
    @requester = User.create!(email_address: "requester@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @user, role: "administrator")
    @organization.memberships.create!(user: @agent, role: "support_agent")
    @organization.memberships.create!(user: @requester, role: "requester")
  end

  def create_request(overrides = {})
    result = ServiceRequests::Create.new(actor: @user, request_id: "request-1").call(
      organization: @organization,
      attributes: { title: "Laptop won't boot", description: "Blue screen on startup.", category: "hardware", priority: "critical" }.merge(overrides),
      requester: @user
    )
    result.record
  end

  test "create persists a service request and domain event atomically" do
    result = nil

    assert_difference [ "ServiceRequest.count", "DomainEvent.count" ], 1 do
      result = ServiceRequests::Create.new(actor: @user, request_id: "request-1").call(
        organization: @organization,
        attributes: { title: "Laptop won't boot", description: "Blue screen on startup.", category: "hardware", priority: "critical" },
        requester: @user
      )
    end

    assert_equal "00000001", result.record.identifier
    assert_equal "open", result.record.status
    assert_equal "service_request.created", result.events.first.event_type
    assert_equal result.record.id, result.events.first.aggregate_id
    assert_equal "request-1", result.events.first.request_id
    assert_equal "administrator", result.events.first.payload["requester_role"]
  end

  test "create increments the sequence identifier" do
    create_request(title: "First", description: "one")
    second = create_request(title: "Second", description: "two")

    assert_equal "00000001", ServiceRequest.order(:identifier).first.identifier
    assert_equal "00000002", second.identifier
  end

  test "create rejects a user outside the tenant" do
    outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")

    assert_raises(TenantBoundary::Violation) do
      ServiceRequests::Create.new(actor: @user).call(
        organization: @organization,
        attributes: { title: "Nope", description: "x", category: "other", priority: "low" },
        requester: outsider
      )
    end
  end

  test "update records before and after state" do
    request = create_request

    result = ServiceRequests::Update.new(actor: @user, request_id: "request-2").call(
      service_request: request,
      attributes: { title: "Laptop replaced", priority: "medium" }
    )

    assert_equal "Laptop won't boot", result.events.first.payload.dig("before", "title")
    assert_equal "Laptop replaced", result.events.first.payload.dig("after", "title")
    assert_equal "service_request.updated", result.events.first.event_type
  end

  test "transition_status publishes a status change event" do
    request = create_request

    result = ServiceRequests::TransitionStatus.new(actor: @user).call(
      service_request: request,
      new_status: "triaged"
    )

    assert_equal "triaged", request.reload.status
    assert_equal "service_request.status_changed", result.events.first.event_type
    assert_equal "open", result.events.first.payload.dig("before", "status")
    assert_equal "triaged", result.events.first.payload.dig("after", "status")
  end

  test "transition_status raises on an invalid transition" do
    request = create_request

    assert_raises(ArgumentError) do
      ServiceRequests::TransitionStatus.new(actor: @user).call(
        service_request: request,
        new_status: "resolved"
      )
    end
    assert request.reload.open?
  end

  test "attach_file stores bytes and records the attachment" do
    request = create_request

    result = ServiceRequests::AttachFile.new(actor: @user).call(
      service_request: request,
      name: "receipt.pdf",
      content_type: "application/pdf",
      bytes: "%PDF-1.4 fake body".b
    )

    attachment = result.record
    assert_equal "receipt.pdf", attachment.stored_file.name
    assert_equal "application/pdf", attachment.stored_file.content_type
    assert_equal "service_request.attached", result.events.first.event_type
    assert attachment.stored_file.checksum.present?
    assert_equal 18, attachment.stored_file.byte_size
    assert_equal request.id, attachment.service_request_id
  end

  test "attach_file refuses a blank file" do
    request = create_request

    assert_raises(ActiveRecord::RecordInvalid) do
      ServiceRequests::AttachFile.new(actor: @user).call(
        service_request: request,
        name: "",
        content_type: "application/octet-stream",
        bytes: ""
      )
    end
  end
end
