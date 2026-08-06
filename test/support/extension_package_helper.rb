# frozen_string_literal: true

module ExtensionPackageHelper
  def extension_package(
    id,
    version: "1.0.0",
    dependencies: [],
    provides: [],
    requires: [],
    configuration: nil,
    migration_paths: [],
    documentation: nil
  )
    manifest = Extensions::Manifest.new({
      "schema_version" => 1,
      "extension" => {
        "id" => id,
        "version" => version,
        "contract_version" => 1,
        "entrypoint" => id.tr(".-", "_")
      },
      "platform" => { "requirement" => ">= 0.9.0, < 1.0.0" },
      "capabilities" => { "provides" => provides, "requires" => requires },
      "dependencies" => dependencies,
      "components" => {
        "configuration" => configuration,
        "migrations" => { "namespace" => id, "paths" => migration_paths },
        "routes" => { "namespace" => id },
        "assets" => { "namespace" => id },
        "documentation" => documentation
      },
      "security" => { "trust" => "trusted_in_process" }
    })
    Extensions::Package.new(
      declaration: extension_declaration(id),
      root: Pathname("/tmp/extensions").join(id),
      manifest:
    )
  end

  def extension_declaration(id)
    {
      "id" => id,
      "package" => id.tr(".", "-"),
      "enabled" => true,
      "required" => true
    }
  end

  def provided_capability(id, version)
    { "id" => id, "version" => version }
  end

  def required_capability(id, requirement)
    { "id" => id, "requirement" => requirement }
  end

  def extension_dependency(id, requirement)
    { "id" => id, "requirement" => requirement }
  end
end
