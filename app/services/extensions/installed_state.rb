# frozen_string_literal: true

module Extensions
  class InstalledState
    def initialize(report:, resolver: ComponentResolver.new, migration_context_factory: nil)
      @report = report
      @resolver = resolver
      @migration_context_factory = migration_context_factory || method(:default_migration_context)
    end

    def call
      packages = report.packages.index_by(&:id)
      report.configuration.enabled.sort_by { |declaration| declaration.fetch("id") }.map do |declaration|
        package = packages[declaration.fetch("id")]
        package ? package_state(package) : unavailable_state(declaration)
      end
    end

    private

    attr_reader :report, :resolver, :migration_context_factory

    def package_state(package)
      components = resolver.resolve(package)
      migrations = migration_state(components)
      finding_codes = findings_for(package.id)
      finding_codes << "extension_migration_state_unavailable" unless migrations.fetch("available")

      {
        "id" => package.id,
        "package" => package.package_name,
        "version" => package.version,
        "required" => package.required?,
        "contract_version" => package.manifest.contract_version,
        "status" => finding_codes.empty? ? "ready" : "blocked",
        "finding_codes" => finding_codes.uniq.sort,
        "capabilities" => package.manifest.provided_capabilities.map(&:dup),
        "components" => component_state(components),
        "pending_migrations" => migrations.fetch("pending")
      }
    rescue ComponentResolver::InvalidComponent
      blocked_package_state(package, "extension_component_invalid")
    end

    def unavailable_state(declaration)
      {
        "id" => declaration.fetch("id"),
        "package" => declaration.fetch("package"),
        "version" => nil,
        "required" => declaration.fetch("required"),
        "contract_version" => nil,
        "status" => "blocked",
        "finding_codes" => findings_for(declaration.fetch("id")).presence || [ "extension_package_missing" ],
        "capabilities" => [],
        "components" => empty_components,
        "pending_migrations" => []
      }
    end

    def blocked_package_state(package, code)
      {
        "id" => package.id,
        "package" => package.package_name,
        "version" => package.version,
        "required" => package.required?,
        "contract_version" => package.manifest.contract_version,
        "status" => "blocked",
        "finding_codes" => (findings_for(package.id) << code).uniq.sort,
        "capabilities" => package.manifest.provided_capabilities.map(&:dup),
        "components" => empty_components,
        "pending_migrations" => []
      }
    end

    def migration_state(components)
      return { "available" => true, "pending" => [] } if components.migration_paths.empty?

      statuses = migration_context_factory.call(components.migration_paths).migrations_status
      pending = statuses.filter_map do |status, version, name|
        next unless status == "down"

        {
          "namespace" => components.migration_namespace,
          "version" => version.to_s,
          "name" => name
        }
      end
      { "available" => true, "pending" => pending }
    rescue StandardError
      { "available" => false, "pending" => [] }
    end

    def default_migration_context(paths)
      connection = ActiveRecord::Base.connection
      ActiveRecord::MigrationContext.new(paths.map(&:to_s), connection.schema_migration)
    end

    def findings_for(extension_id)
      report.blockers.filter_map do |finding|
        details = finding.fetch(:details)
        scoped_id = details[:extension_id] || details["id"]
        next unless scoped_id.nil? || scoped_id == extension_id

        finding.fetch(:code)
      end
    end

    def component_state(components)
      {
        "configuration" => !components.configuration.nil?,
        "migrations" => {
          "namespace" => components.migration_namespace,
          "paths" => components.migration_paths.size
        },
        "routes" => { "namespace" => components.routes_namespace },
        "assets" => { "namespace" => components.assets_namespace },
        "documentation" => !components.documentation.nil?
      }
    end

    def empty_components
      {
        "configuration" => false,
        "migrations" => { "namespace" => nil, "paths" => 0 },
        "routes" => { "namespace" => nil },
        "assets" => { "namespace" => nil },
        "documentation" => false
      }
    end
  end
end
