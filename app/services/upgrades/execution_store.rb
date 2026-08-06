# frozen_string_literal: true

require "json"

module Upgrades
  class ExecutionStore
    def initialize(path: Rails.root.join("var/upgrade/execution.json"))
      @path = Pathname(path)
    end

    def read
      path.exist? ? JSON.parse(path.read) : nil
    rescue JSON::ParserError
      raise InvalidState, "upgrade execution state is invalid"
    end

    def write!(payload)
      path.dirname.mkpath
      temporary = path.sub_ext(".tmp")
      temporary.write(JSON.pretty_generate(payload) + "\n")
      File.rename(temporary, path)
      payload
    ensure
      temporary&.delete if temporary&.exist?
    end

    private

    attr_reader :path

    class InvalidState < StandardError; end
  end
end
