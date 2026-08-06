# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class DistributionCertificationTest < ActiveSupport::TestCase
  setup do
    @root = Pathname(Dir.mktmpdir("distribution-certification-", Rails.root.join("tmp")))
    @evidence = @root.join("evidence")
    @output = @root.join("bundle")
    @commit = "a" * 40
    @digest = "sha256:#{'d' * 64}"
    @repository = "owner/platform"
    @release_directory = Rails.root.join("docs/releases/0.8.0")
    @evidence.mkpath
    write_packaging_evidence
  end

  teardown { FileUtils.rm_rf(@root) }

  test "certifies preparation preflight publication plans verification and replay protection" do
    result = builder.build!
    manifest = Distributions::Manifest.load(@output.join("distribution-manifest.json"))
    metadata = JSON.parse(@output.join("release-metadata.json").read)
    compatibility = JSON.parse(@output.join("artifacts/compatibility.json").read)

    assert_equal "ready", result.fetch(:status)
    assert_equal "0.8.0", result.fetch(:version)
    assert preflight(manifest, metadata, compatibility, absent_states).ready?

    release_plan = Distributions::GithubReleasePlan.new(
      manifest: manifest,
      artifact_directory: @output.join("artifacts")
    )
    ghcr_plan = Distributions::GhcrPromotionPlan.new(
      manifest: manifest,
      repository: @repository,
      digest: @digest
    )
    verifier = Distributions::Verifier.new(
      manifest: manifest,
      repository: @repository,
      github_release_plan: release_plan,
      ghcr_plan: ghcr_plan,
      channel_states: published_states(ghcr_plan)
    )

    assert release_plan.prerelease?
    assert_equal 11, release_plan.asset_paths.size
    assert_equal %W[
      ghcr.io/owner/platform:0.8.0
      ghcr.io/owner/platform:0.8
    ], ghcr_plan.semantic_tags
    assert verifier.ready?
    assert_equal "published", verifier.verify.fetch(:status)
    assert_equal %w[publication_replay publication_replay],
      preflight(manifest, metadata, compatibility, published_states(ghcr_plan))
        .blockers
        .pluck(:code)
  end

  test "rejects packaging evidence from another source commit" do
    manifest = JSON.parse(@evidence.join("packaging-manifest.json").read)
    manifest["source"]["commit"] = "b" * 40
    @evidence.join("packaging-manifest.json").write("#{JSON.pretty_generate(manifest)}\n")

    error = assert_raises(Distributions::BundleBuilder::InvalidBundle) { builder.build! }

    assert_equal "release evidence belongs to another commit", error.message
    refute @output.exist?
  end

  private

  def builder
    Distributions::BundleBuilder.new(
      release_directory: @release_directory,
      evidence_directory: @evidence,
      output: @output,
      source_commit: @commit
    )
  end

  def preflight(manifest, metadata, compatibility, states)
    Distributions::Inspector.new(
      manifest: manifest,
      release_metadata: metadata,
      compatibility: compatibility,
      repository: @repository,
      source_commit: @commit,
      source_branch: "main",
      channel_states: states
    ).preflight
  end

  def absent_states
    %w[github_release ghcr].map do |channel|
      channel_state(channel:, status: "absent")
    end
  end

  def published_states(ghcr_plan)
    [
      channel_state(
        channel: "github_release",
        status: "available",
        immutable_reference: "https://github.com/#{@repository}/releases/tag/v0.8.0",
        observed_commit: @commit
      ),
      channel_state(
        channel: "ghcr",
        status: "available",
        immutable_reference: ghcr_plan.immutable_reference,
        observed_commit: @commit
      )
    ]
  end

  def channel_state(
    channel:,
    status:,
    immutable_reference: nil,
    observed_commit: nil
  )
    Distributions::ChannelState.new(
      "schema_version" => 1,
      "channel" => channel,
      "repository" => @repository,
      "version" => "0.8.0",
      "tag" => "v0.8.0",
      "status" => status,
      "immutable_reference" => immutable_reference,
      "observed_commit" => observed_commit,
      "findings" => []
    )
  end

  def write_packaging_evidence
    write_json("sbom.cdx.json", sbom)
    write_json("container-sbom.cdx.json", sbom)
    write_json(
      "packaging-manifest.json",
      {
        schema_version: 1,
        source: {
          repository: "https://github.com/#{@repository}",
          commit: @commit,
          version: "0.8.0"
        },
        image: {
          labels: {
            "org.opencontainers.image.version" => "0.8.0"
          }
        }
      }
    )
    write_json(
      "release-provenance.json",
      {
        predicate: {
          buildDefinition: {
            externalParameters: {
              platform_version: "0.8.0",
              source_commit: @commit
            }
          }
        }
      }
    )
  end

  def sbom
    {
      metadata: {
        component: { version: "0.8.0" },
        properties: [
          { name: "source.commit", value: @commit },
          { name: "platform.version", value: "0.8.0" }
        ]
      }
    }
  end

  def write_json(filename, value)
    @evidence.join(filename).write("#{JSON.pretty_generate(value)}\n")
  end
end
