# frozen_string_literal: true

module Epic10
  class RepresentativeApplicationCertification
    COMMIT_PATTERN = /\A[0-9a-f]{40}\z/
    JOURNEYS = {
      "foundation" => "test/support/representative_application/foundation.yml",
      "design_i18n_grid" => "test/support/representative_application/design_i18n_grid.yml",
      "domain_services" => "test/support/representative_application/domain_services.yml",
      "multitenant_extension" => "test/support/representative_application/multitenant_extension.yml"
    }.freeze

    def initialize(source_commit:, root: Rails.root)
      @source_commit = source_commit
      @root = Pathname(root)
    end

    def call
      invalid!("source commit must be a full lowercase Git SHA") unless COMMIT_PATTERN.match?(@source_commit)
      architecture = RepresentativeApplication.load(
        architecture_path: @root.join("config/epic_10/representative-application.yml"),
        foundation_path: @root.join(JOURNEYS.fetch("foundation"))
      )
      RepresentativeApplicationJourney.load(@root.join(JOURNEYS.fetch("design_i18n_grid")))
      DomainServicesJourney.load(@root.join(JOURNEYS.fetch("domain_services")))
      MultitenantExtensionJourney.load(@root.join(JOURNEYS.fetch("multitenant_extension")))

      missing = JOURNEYS.values.reject { |path| @root.join(path).file? }
      invalid!("missing journey evidence: #{missing.join(', ')}") if missing.any?

      {
        "schema_version" => 1,
        "phase" => 2,
        "status" => "passed",
        "source_commit" => @source_commit,
        "application_id" => architecture.architecture.fetch("id"),
        "journeys" => JOURNEYS.keys,
        "public_contracts_only" => true,
        "credential_free" => true,
        "private_maintainer_context_required" => false,
        "publication" => { "allowed" => false }
      }.freeze
    rescue RepresentativeApplication::InvalidFoundation,
      RepresentativeApplicationJourney::InvalidJourney,
      DomainServicesJourney::InvalidJourney,
      MultitenantExtensionJourney::InvalidJourney,
      Errno::ENOENT => error
      invalid!(error.message)
    end

    private

    def invalid!(message) = raise InvalidCertification, message

    class InvalidCertification < StandardError; end
  end
end
