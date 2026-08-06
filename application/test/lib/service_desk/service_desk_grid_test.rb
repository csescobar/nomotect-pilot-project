require "test_helper"

class ServiceDeskGridTest < ActiveSupport::TestCase
  setup do
    @admin = User.create!(email_address: "admin@example.com", password: "a-secure-password")
    @requester = User.create!(email_address: "requester@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @admin, role: "administrator")
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

  test "service_requests grid is registered in the catalog" do
    definition = GridEngine::Catalog.fetch("service_requests")

    assert_equal "service_requests", definition.key
    assert_equal ServiceRequest, definition.model_class
    assert_includes definition.columns.keys, "identifier"
    assert_includes definition.columns.keys, "created_at"
  end

  test "scope_for returns all requests for a reader" do
    scope = GridEngine::Catalog.scope_for("service_requests", user: @admin, organization: @organization)

    assert_equal [ @request ], scope.to_a
  end

  test "scope_for narrows a requester to their own requests" do
    others_request = ServiceRequest.create!(
      organization: @organization,
      requester: @admin,
      identifier: "00000002",
      title: "Someone else's request",
      description: "not mine",
      category: "software",
      priority: "low"
    )
    scope = GridEngine::Catalog.scope_for("service_requests", user: @requester, organization: @organization)

    assert_includes scope.to_a.map(&:id), @request.id
    assert_not_includes scope.to_a.map(&:id), others_request.id
  end

  test "scope_for returns none for a non-member" do
    outsider = User.create!(email_address: "outsider@example.com", password: "a-secure-password")
    scope = GridEngine::Catalog.scope_for("service_requests", user: outsider, organization: @organization)

    assert_empty scope.to_a
  end

  test "scope_for returns none without an organization" do
    scope = GridEngine::Catalog.scope_for("service_requests", user: @admin, organization: nil)

    assert_empty scope.to_a
  end

  test "grid definition renders with the html renderer" do
    definition = GridEngine::Catalog.fetch("service_requests")
    fragment = GridEngine::HtmlRenderer.new(definition, [ @request ]).call.to_s

    assert_includes fragment, "VPN access"
    assert_includes fragment, "network"
  end
end
