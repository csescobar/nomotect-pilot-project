require "test_helper"

class SecurityPrivacyTest < ActiveSupport::TestCase
  setup do
    suffix = SecureRandom.hex(4)
    @organization = Organization.create!(name: "Privacy #{suffix}")
    @user = User.create!(email_address: "privacy-#{suffix}@example.com", password: "correct horse battery staple")
    Membership.create!(organization: @organization, user: @user, role: "owner")
  end

  test "exports only the requesting tenant context with a checksum" do
    request = PrivacyRequest.create!(organization: @organization, requested_by: @user, kind: "export")

    Privacy::DataExporter.call(request: request)

    request.reload
    assert_equal "completed", request.status
    assert_equal @organization.id, request.result.dig("payload", "organization", "id")
    assert_equal @user.email_address, request.result.dig("payload", "user", "email_address")
    assert_match(/\A[0-9a-f]{64}\z/, request.result.fetch("sha256"))
  end

  test "rejects export when requester no longer belongs to tenant" do
    replacement = User.create!(email_address: "replacement-#{SecureRandom.hex(4)}@example.com", password: "correct horse battery staple")
    Membership.create!(organization: @organization, user: replacement, role: "owner")
    request = PrivacyRequest.create!(organization: @organization, requested_by: @user, kind: "export")
    @organization.memberships.find_by!(user: @user).destroy!

    assert_raises(TenantBoundary::Violation) { Privacy::DataExporter.call(request: request) }
  end

  test "anonymizes matching tenant customer and removes preferences" do
    customer = Customer.create!(organization: @organization, name: "Personal", email_address: @user.email_address, status: "active")
    PrivacyPreference.create!(organization: @organization, user: @user, purpose: "product_updates", granted: true, decided_at: Time.current)
    request = PrivacyRequest.create!(organization: @organization, requested_by: @user, kind: "anonymize")

    Privacy::Anonymizer.call(request: request)

    assert_equal "inactive", customer.reload.status
    assert_match(/anonymized-#{customer.id}/, customer.email_address)
    assert_not PrivacyPreference.exists?(organization: @organization, user: @user)
    assert_equal "completed", request.reload.status
  end

  test "throttle hashes identity and blocks above limit" do
    cache = ActiveSupport::Cache::MemoryStore.new
    first = Security::Throttle.check!(scope: "test", identity: "private@example.com", limit: 1, period: 1.minute, cache: cache)
    second = Security::Throttle.check!(scope: "test", identity: "private@example.com", limit: 1, period: 1.minute, cache: cache)

    assert first.allowed
    assert_not second.allowed
    assert_operator second.retry_after, :>, 0
  end

  test "secret registry identifies sensitive keys" do
    assert Security::SecretRegistry.redacted?(:webhook_secret)
    assert Security::SecretRegistry.redacted?("Authorization")
    assert_not Security::SecretRegistry.redacted?(:organization_id)
  end
end
