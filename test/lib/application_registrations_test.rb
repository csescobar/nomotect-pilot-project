require "test_helper"

class ApplicationRegistrationsTest < ActiveSupport::TestCase
  test "custom roles expose explicit permissions without administrative privilege" do
    registry = ApplicationRoles::Registry.new
    registry.register(:risk_manager, permissions: %w[risks.read])
    entry = registry.fetch(:risk_manager)
    assert_equal %w[risks.read], entry.permissions
    assert_not entry.protected
  end

  test "protected roles cannot be replaced" do
    registry = ApplicationRoles::Registry.new
    assert_raises(ArgumentError) { registry.register(:owner, permissions: []) }
  end

  test "grid catalog rejects replacement and requires authorized scope" do
    registry = GridEngine::Catalog::Registry.new
    organizations = GridEngine::Definition.new(key: :organizations, model_class: Organization)
    unsafe = GridEngine::Definition.new(key: :unsafe, model_class: Organization)
    assert_raises(ArgumentError) { registry.register("organizations", definition: organizations, scope: ->(**) { Organization.all }) }
    assert_raises(ArgumentError) { registry.register("unsafe", definition: unsafe, scope: nil) }
  end

  test "registries are sealed after application configuration loads" do
    assert ApplicationRoles.registry.sealed?
    assert GridEngine::Catalog.registry.sealed?
    assert_raises(RuntimeError) { ApplicationRoles.register(:late_role, permissions: []) }
  end
end
