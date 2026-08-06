# frozen_string_literal: true

require "digest"
require "pathname"

module Epic10
  class RcPreparation
    TARGET_PATTERN = /\A1\.0\.0-rc\.([1-9]\d*)\z/
    COMMIT_PATTERN = /\A[0-9a-f]{40}\z/
    REQUIRED_EVIDENCE = %w[
      release_notes
      compatibility
      application_sbom
      container_sbom
      packaging_manifest
      provenance
      epic_10_validation
      release_baseline
    ].freeze

    attr_reader :target_version, :source_commit

    def initialize(target_version:, source_commit:, root: Rails.root)
      @root = Pathname(root)
      @target_version = Platform::Version.new(target_version).to_s
      @source_commit = String(source_commit)
    end

    def validate
      findings = []
      findings << "target version must be an Epic 10 release candidate" unless TARGET_PATTERN.match?(target_version)
      findings << "source commit must be a full lowercase Git SHA" unless COMMIT_PATTERN.match?(source_commit)
      findings << "VERSION must remain 0.9.0 during RC planning" unless current_version == "0.9.0"
      required_paths.each do |path|
        findings << "required RC planning input is missing: #{relative(path)}" unless path.file?
      end
      begin
        ReleaseBaseline.load(release_baseline_path) if release_baseline_path.file?
      rescue ReleaseBaseline::InvalidBaseline => error
        findings << "release baseline is invalid: #{error.message}"
      end
      findings
    rescue Platform::Version::InvalidVersion => error
      [ error.message ]
    end

    def plan
      ensure_valid!
      baseline = ReleaseBaseline.load(release_baseline_path)
      catalog = Releases::ChangeCatalog.new(path: root.join("changes"))
      fragments = catalog.fragments.sort_by(&:id)

      {
        schema_version: 1,
        status: "review_required",
        source_version: current_version,
        target_version:,
        tag: "v#{target_version}",
        source_commit:,
        inputs: {
          release_baseline_digest: digest(baseline.data),
          changelog_digest: Digest::SHA256.file(changelog_path).hexdigest,
          fragment_ids: fragments.map(&:id),
          fragment_digest: digest(fragments.map(&:data))
        },
        required_evidence: REQUIRED_EVIDENCE,
        approval: {
          environment: "release-candidate",
          required: true,
          approved: false
        },
        publication: {
          allowed: false,
          tag_created: false,
          artifacts_published: false
        }
      }.freeze
    end

    private

    attr_reader :root

    def ensure_valid!
      findings = validate
      raise InvalidPreparation, findings.join("; ") if findings.any?
    end

    def current_version
      @current_version ||= Platform::Version.current(path: version_path).to_s
    end

    def required_paths
      [ version_path, changelog_path, release_baseline_path ]
    end

    def version_path = root.join("VERSION")
    def changelog_path = root.join("CHANGELOG.md")
    def release_baseline_path = root.join("config/epic_10/release-baseline.yml")
    def relative(path) = path.relative_path_from(root).to_s

    def digest(value)
      Digest::SHA256.hexdigest(Releases::CanonicalJson.generate(value))
    end

    class InvalidPreparation < StandardError; end
  end
end
