require "test_helper"

class ServiceRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = User.create!(email_address: "admin@example.com", password: "a-secure-password")
    @agent = User.create!(email_address: "agent@example.com", password: "a-secure-password")
    @service_requester = User.create!(email_address: "requester@example.com", password: "a-secure-password")
    @outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @admin, role: "administrator")
    @organization.memberships.create!(user: @agent, role: "support_agent")
    @organization.memberships.create!(user: @service_requester, role: "requester")
    @service_request = ServiceRequest.create!(
      organization: @organization,
      requester: @service_requester,
      identifier: "00000001",
      title: "VPN access",
      description: "Cannot reach the office network.",
      category: "network",
      priority: "high"
    )
  end

  test "member can view the service request index" do
    sign_in(@admin)

    get organization_service_requests_path(@organization)

    assert_response :success
    assert_select "h1", text: /Service Requests/
    assert_select ".grid-page-container", count: 1
  end

  test "outsider cannot view the service request index" do
    sign_in(@outsider)

    get organization_service_requests_path(@organization)

    assert_response :forbidden
  end

  test "administrator can view request details" do
    sign_in(@admin)

    get organization_service_request_path(@organization, @service_request)

    assert_response :success
    assert_select "h1", text: /VPN access/
    assert_select ".ui-property-list", count: 1
  end

  test "requester can view their own request" do
    sign_in(@service_requester)

    get organization_service_request_path(@organization, @service_request)

    assert_response :success
  end

  test "requester cannot view another user's request" do
    other = ServiceRequest.create!(
      organization: @organization,
      requester: @agent,
      identifier: "00000002",
      title: "Secret",
      description: "confidential",
      category: "other",
      priority: "low"
    )
    sign_in(@service_requester)

    get organization_service_request_path(@organization, other)

    assert_response :forbidden
  end

  test "outsider cannot view request details" do
    sign_in(@outsider)

    get organization_service_request_path(@organization, @service_request)

    assert_response :forbidden
  end

  test "administrator creates a service request through the operation" do
    sign_in(@admin)

    assert_difference [ "ServiceRequest.count", "DomainEvent.count" ], 1 do
      post organization_service_requests_path(@organization), params: {
        authenticity_token: csrf_token,
        service_request: { title: "New laptop", description: "Replace my 2019 unit.", category: "hardware", priority: "medium" }
      }
    end

    assert_redirected_to organization_service_request_path(@organization, ServiceRequest.last)
    assert_equal "00000002", ServiceRequest.last.identifier
  end

  test "regular agent cannot create a service request" do
    sign_in(@agent)

    assert_no_difference "ServiceRequest.count" do
      post organization_service_requests_path(@organization), params: {
        authenticity_token: csrf_token,
        service_request: { title: "New laptop", description: "Replace", category: "hardware", priority: "medium" }
      }
    end

    assert_response :forbidden
  end

  test "administrator transitions a request status" do
    sign_in(@admin)

    patch transition_organization_service_request_path(@organization, @service_request), params: {
      authenticity_token: csrf_token,
      status: "triaged"
    }

    assert_redirected_to organization_service_request_path(@organization, @service_request)
    assert_equal "triaged", @service_request.reload.status
  end

  test "invalid transition redirects with a flash alert" do
    sign_in(@admin)

    patch transition_organization_service_request_path(@organization, @service_request), params: {
      authenticity_token: csrf_token,
      status: "resolved"
    }

    assert_redirected_to organization_service_request_path(@organization, @service_request)
    assert_equal "open", @service_request.reload.status
  end

  test "administrator assigns a support agent" do
    sign_in(@admin)

    patch assign_organization_service_request_path(@organization, @service_request), params: {
      authenticity_token: csrf_token,
      service_request: { assigned_support_agent_id: @agent.id }
    }

    assert_redirected_to organization_service_request_path(@organization, @service_request)
    assert_equal @agent.id, @service_request.reload.assigned_support_agent_id
  end

  test "assigning a non-member agent redirects with a flash alert" do
    sign_in(@admin)

    patch assign_organization_service_request_path(@organization, @service_request), params: {
      authenticity_token: csrf_token,
      service_request: { assigned_support_agent_id: @outsider.id }
    }

    assert_redirected_to organization_service_request_path(@organization, @service_request)
    assert_nil @service_request.reload.assigned_support_agent_id
  end

  test "administrator attaches a file to a request" do
    sign_in(@admin)

    assert_difference [ "ServiceRequestAttachment.count", "StoredFile.count" ], 1 do
      post attach_organization_service_request_path(@organization, @service_request), params: {
        authenticity_token: csrf_token,
        service_request: { file: fixture_file_upload("sample.txt", "text/plain") }
      }
    end

    assert_redirected_to organization_service_request_path(@organization, @service_request)
  end

  private

  def sign_in(user)
    get new_session_path
    token = Nokogiri::HTML(response.body).at_css("input[name='authenticity_token']")["value"]
    post session_path, params: { authenticity_token: token, email_address: user.email_address, password: "a-secure-password" }
    follow_redirect!
  end

  def csrf_token
    Nokogiri::HTML(response.body).at_css("meta[name='csrf-token']")["content"]
  end
end
