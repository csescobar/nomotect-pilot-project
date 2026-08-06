# frozen_string_literal: true

module Distributions
  class GhcrPromotionPlan
    DIGEST = /\Asha256:[a-f0-9]{64}\z/
    REPOSITORY = /\A[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+\z/

    attr_reader :manifest, :repository, :digest

    def initialize(manifest:, repository:, digest:)
      @manifest = manifest
      @repository = repository
      @digest = digest
      validate!
    end

    def image = "ghcr.io/#{repository.downcase}"
    def immutable_reference = "#{image}@#{digest}"
    def commit_tag = "#{image}:sha-#{manifest.commit[0, 12]}"

    def semantic_tags
      segments = manifest.version.split(".")
      [ "#{image}:#{manifest.version}", "#{image}:#{segments.first(2).join('.')}" ]
    end

    def to_h
      {
        schema_version: 1,
        channel: "ghcr",
        version: manifest.version,
        source_commit: manifest.commit,
        source_tag: commit_tag,
        source_digest: digest,
        immutable_reference: immutable_reference,
        destination_tags: semantic_tags,
        rebuild: false,
        latest: false
      }
    end

    private

    def validate!
      raise InvalidPromotion, "repository has an invalid format" unless REPOSITORY.match?(repository)
      raise InvalidPromotion, "image digest has an invalid format" unless DIGEST.match?(digest)
      raise InvalidPromotion, "latest cannot be a promotion target" if
        semantic_tags.any? { |tag| tag.end_with?(":latest") }
      raise InvalidPromotion, "semantic promotion tags must be unique" unless semantic_tags.uniq == semantic_tags
    end

    class InvalidPromotion < StandardError; end
  end
end
