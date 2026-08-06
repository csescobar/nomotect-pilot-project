require "test_helper"

class PlatformRoleTest < ActiveSupport::TestCase
  test "accepts only the global platform administrator role" do
    role = PlatformRole.new(role: "tenant_owner")

    assert_not role.valid?
    assert role.errors[:role].present?
  end

  test "identifies platform administrators" do
    assert PlatformRole.new(role: "platform_admin").platform_admin?
    assert_not PlatformRole.new(role: "tenant_owner").platform_admin?
  end
end
