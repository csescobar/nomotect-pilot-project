# frozen_string_literal: true

require "digest"
require "json"
require "pathname"

module RepositoryIntelligence
  class SnapshotDrift
    Result = Data.define(:fresh, :expected_sha256, :actual_sha256, :findings)

    def initialize(snapshot_path:, checksum_path: nil)
      @snapshot_path = Pathname(snapshot_path)
      @checksum_path = Pathname(checksum_path || "#{snapshot_path}.sha256")
    end

    def validate(payload)
      generated = JSON.pretty_generate(payload) << "\n"
      actual = Digest::SHA256.hexdigest(generated)
      findings = []
      findings << "snapshot is missing" unless snapshot_path.file?
      findings << "snapshot checksum is missing" unless checksum_path.file?

      expected = checksum_path.file? ? checksum_path.read.split.first : nil
      findings << "generated snapshot differs from committed checksum" if expected && expected != actual
      findings << "committed snapshot content differs from generated output" if snapshot_path.file? && snapshot_path.read != generated

      Result.new(fresh: findings.empty?, expected_sha256: expected, actual_sha256: actual, findings:)
    end

    private

    attr_reader :snapshot_path, :checksum_path
  end
end
