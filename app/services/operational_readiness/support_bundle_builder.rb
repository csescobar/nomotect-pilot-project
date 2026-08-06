# frozen_string_literal: true

require "digest"
require "json"
require "fileutils"

module OperationalReadiness
  class SupportBundleBuilder
    DEFAULT_MAX_ENTRY_BYTES = 512.kilobytes
    DEFAULT_MAX_BUNDLE_BYTES = 5.megabytes

    def initialize(registry:, output:, redactor: DiagnosticRedactor.new, source:,
      max_entry_bytes: DEFAULT_MAX_ENTRY_BYTES, max_bundle_bytes: DEFAULT_MAX_BUNDLE_BYTES,
      clock: -> { Time.current.utc })
      @registry = registry
      @output = Pathname(output)
      @redactor = redactor
      @source = source
      @max_entry_bytes = max_entry_bytes
      @max_bundle_bytes = max_bundle_bytes
      @clock = clock
    end

    def inspect(selected: nil)
      build_payload(selected:).fetch(:manifest)
    end

    def build!(selected: nil)
      payload = build_payload(selected:)
      raise InvalidOutput, "support bundle output already exists" if output.exist?

      output.dirname.mkpath
      temporary = output.dirname.join(".#{output.basename}.tmp-#{Process.pid}")
      FileUtils.rm_rf(temporary)
      temporary.join("reports").mkpath
      File.chmod(0o700, temporary)
      payload.fetch(:reports).each do |path, content|
        destination = temporary.join(path)
        destination.write(content)
        File.chmod(0o600, destination)
      end
      manifest_path = temporary.join("manifest.json")
      manifest_path.write("#{JSON.pretty_generate(payload.fetch(:manifest).data)}\n")
      File.chmod(0o600, manifest_path)
      File.rename(temporary, output)
      payload.fetch(:manifest)
    ensure
      FileUtils.rm_rf(temporary) if temporary&.exist?
    end

    private

    attr_reader :registry, :output, :redactor, :source, :max_entry_bytes, :max_bundle_bytes, :clock

    def build_payload(selected:)
      total = 0
      redactions = Hash.new(0)
      files = []
      reports = registry.collect(selected:).sort.to_h do |id, value|
        result = redactor.redact(value)
        result.redactions.each { |category, count| redactions[category] += count }
        content = "#{JSON.pretty_generate(result.value)}\n"
        raise SizeLimitExceeded, "diagnostic report exceeds the entry size limit" if content.bytesize > max_entry_bytes

        total += content.bytesize
        raise SizeLimitExceeded, "support bundle exceeds the total size limit" if total > max_bundle_bytes

        path = "reports/#{id}.json"
        files << {
          "id" => id,
          "path" => path,
          "media_type" => "application/json",
          "size_bytes" => content.bytesize,
          "checksum" => "sha256:#{Digest::SHA256.hexdigest(content)}"
        }
        [ path, content ]
      end
      manifest = SupportBundleManifest.new(
        "schema_version" => 1,
        "id" => "support-#{clock.call.utc.strftime('%Y%m%dT%H%M%SZ')}",
        "generated_at" => clock.call.utc.iso8601,
        "source" => source,
        "limits" => {
          "max_entry_bytes" => max_entry_bytes,
          "max_bundle_bytes" => max_bundle_bytes
        },
        "files" => files,
        "redactions" => redactions.sort.to_h,
        "automated_upload" => false
      )
      { manifest:, reports: }
    rescue JSON::GeneratorError, DiagnosticRedactor::RedactionFailed
      raise RedactionFailed, "support bundle redaction could not be certified"
    end

    class SizeLimitExceeded < StandardError; end
    class InvalidOutput < StandardError; end
    class RedactionFailed < StandardError; end
  end
end
