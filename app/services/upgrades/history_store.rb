# frozen_string_literal: true

require "json"

module Upgrades
  class HistoryStore
    SCHEMA_VERSION = 1

    def initialize(path: Rails.root.join("var/upgrade/history.json"), lock: nil)
      @path = Pathname(path)
      @lock = lock || Installation::ExecutionLock.new(path: "#{path}.lock")
    end

    def records
      return [] unless path.exist?

      payload = JSON.parse(path.read)
      raise InvalidHistory, "upgrade history must be an array" unless payload.is_a?(Array)
      payload
    rescue JSON::ParserError
      raise InvalidHistory, "upgrade history is invalid"
    end

    def completed_digest?(digest)
      records.any? { |record| record["status"] == "completed" && record["manifest_digest"] == digest }
    end

    def append!(record)
      lock.synchronize do
        digest = record.fetch("manifest_digest")
        raise ReplayDetected, "completed upgrade manifest has already been recorded" if completed_digest?(digest)

        updated = records + [ record ]
        path.dirname.mkpath
        temporary = path.sub_ext(".tmp")
        temporary.write(JSON.pretty_generate(updated) + "\n")
        File.rename(temporary, path)
        record
      ensure
        temporary&.delete if temporary&.exist?
      end
    end

    private

    attr_reader :path, :lock

    class InvalidHistory < StandardError; end
    class ReplayDetected < StandardError; end
  end
end
