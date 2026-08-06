# frozen_string_literal: true

require "test_helper"
require_relative "../../support/extension_package_helper"
require_relative "../../../app/services/extensions/sdk"

module Extensions
  class RegistryTest < ActiveSupport::TestCase
    include ExtensionPackageHelper

    test "registers declared capabilities and component hooks" do
      package = extension_package(
        "acme.audit",
        provides: [ provided_capability("audit.events", 1) ],
        configuration: "config/extension.schema.json"
      )
      registry = Registry.new

      registry.register(package, package.id) do |extension|
        extension.capability("audit.events", version: 1, provider: -> { :event })
        extension.configuration -> { :configuration }
      end
      registry.seal!

      assert registry.sealed?
      assert_equal [ "acme.audit" ], registry.registered_ids
      assert_equal [ "audit.events" ], registry.fetch("acme.audit").capabilities.keys
      assert_equal [ :configuration ], registry.fetch("acme.audit").hooks.keys
    end

    test "rejects undeclared capabilities without committing a partial registration" do
      package = extension_package("acme.audit")
      registry = Registry.new

      assert_raises(Registry::UndeclaredCapability) do
        registry.register(package, package.id) do |extension|
          extension.capability("audit.private", version: 1, provider: -> { :event })
        end
      end

      assert_empty registry.registered_ids
    end

    test "requires every declared capability to register" do
      package = extension_package(
        "acme.audit",
        provides: [ provided_capability("audit.events", 1) ]
      )

      assert_raises(Registry::MissingCapability) do
        Registry.new.register(package, package.id) { |_extension| }
      end
    end

    test "rejects component hooks not declared by the manifest" do
      package = extension_package("acme.audit")

      assert_raises(Registry::UndeclaredHook) do
        Registry.new.register(package, package.id) do |extension|
          extension.configuration -> { :configuration }
        end
      end
    end

    test "rejects registration outside an active loader context" do
      assert_raises(RegistrationContext::RegistrationUnavailable) do
        Extensions.register("acme.audit") { |_extension| }
      end
    end
  end
end
