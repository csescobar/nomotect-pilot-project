# frozen_string_literal: true

require "json"

module Upgrades
  class MaintenanceControl
    SCHEMA_VERSION = 1

    def initialize(path: Rails.root.join("var/upgrade/maintenance.json"), clock: -> { Time.current.utc })
      @path = Pathname(path)
      @clock = clock
    end

    def activate!
      write!("active" => true, "activated_at" => clock.call.iso8601)
    end

    def deactivate!
      write!("active" => false, "activated_at" => nil)
    end

    def active?
      read.fetch("active")
    end

    def read
      return { "schema_version" => SCHEMA_VERSION, "active" => false, "activated_at" => nil } unless path.exist?

      payload = JSON.parse(path.read)
      raise InvalidState, "unsupported maintenance state" unless payload["schema_version"] == SCHEMA_VERSION
      payload
    rescue JSON::ParserError
      raise InvalidState, "maintenance state is invalid"
    end

    private

    attr_reader :path, :clock

    def write!(attributes)
      payload = { "schema_version" => SCHEMA_VERSION }.merge(attributes)
      path.dirname.mkpath
      temporary = path.sub_ext(".tmp")
      temporary.write(JSON.pretty_generate(payload) + "\n")
      File.rename(temporary, path)
      payload
    ensure
      temporary&.delete if temporary&.exist?
    end

    class InvalidState < StandardError; end
  end
end
