require "application_system_test_case"

class ServiceRequestsSystemTest < ApplicationSystemTestCase
  setup do
    @admin = User.create!(email_address: "system-admin@example.com", password: "a-secure-password")
    @requester = User.create!(email_address: "system-requester@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "System Desk")
    @organization.memberships.create!(user: @admin, role: "administrator")
    @organization.memberships.create!(user: @requester, role: "requester")
    @request = ServiceRequest.create!(
      organization: @organization,
      requester: @requester,
      identifier: "00000001",
      title: "Broken keyboard",
      description: "The Enter key fell off.",
      category: "hardware",
      priority: "high"
    )
  end

  test "requester creates a service request and the admin transitions it" do
    sign_in(@requester)

    visit new_organization_service_request_path(@organization)

    assert_selector "h1", text: /New Service Request/
    fill_in "service_request_title", with: "Monitor flickers"
    fill_in "service_request_description", with: "Screen flickers after warmup."
    select "Hardware", from: "service_request_category"
    select "Medium", from: "service_request_priority"
    click_button "Save"

    assert_text "Service request was created."
    assert_selector "h1", text: /00000002/

    sign_out
    sign_in(@admin)

    visit organization_service_request_path(@organization, ServiceRequest.last)
    assert_selector "h1", text: /00000002/
    assert_text "Monitor flickers"

    click_button "Mark as triaged"
    assert_text "Status changed."
    assert_text "Triaged"
  end

  test "requester can only see their own requests" do
    sign_in(@requester)

    visit organization_service_requests_path(@organization)

    assert_selector ".grid-page-container"
    assert_no_text "Broken keyboard"
  end

  test "admin sees all requests in the grid" do
    sign_in(@admin)

    visit organization_service_requests_path(@organization)

    assert_selector ".grid-page-container"
    assert_text "Broken keyboard"
  end

  test "admin assigns a request to a support agent" do
    agent = User.create!(email_address: "system-agent@example.com", password: "a-secure-password")
    @organization.memberships.create!(user: agent, role: "support_agent")
    sign_in(@admin)

    visit organization_service_request_path(@organization, @request)

    select agent.email_address, from: "service_request_assigned_support_agent_id"
    click_button "Assign"

    assert_text "Agent assigned."
    assert_text agent.email_address
  end

  private

  def sign_in(user)
    visit new_session_path
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "a-secure-password"
    click_button "Sign in"
  end

  def sign_out
    click_button "Sign out"
    assert_text "Sign in"
  end
end
