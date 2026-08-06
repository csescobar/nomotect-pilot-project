require "json"

module Installation
  class StateStore
    SCHEMA_VERSION = 1

    def initialize(path: default_path, environment: Rails.env)
      @path = Pathname(path)
      @environment = environment.to_s
    end

    attr_reader :path, :environment

    def read
      return default_state unless path.exist?

      payload = JSON.parse(path.read)
      validate!(payload)
      payload
    rescue JSON::ParserError => error
      raise InvalidState, "Invalid installation state JSON: #{error.message}"
    end

    def write!(state:, metadata: {})
      machine = StateMachine.new(state)
      payload = {
        "schema_version" => SCHEMA_VERSION,
        "environment" => environment,
        "state" => machine.state,
        "updated_at" => Time.current.utc.iso8601,
        "metadata" => metadata
      }
      path.dirname.mkpath
      temporary = path.sub_ext("#{path.extname}.tmp")
      temporary.write(JSON.pretty_generate(payload) + "\n")
      File.rename(temporary, path)
      payload
    ensure
      temporary&.delete if temporary&.exist?
    end

    def completed?
      StateMachine.new(read.fetch("state")).completed?
    end

    private

    def default_path
      Pathname(ENV.fetch("INSTALLATION_STATE_PATH", Rails.root.join("var/installation/state.#{Rails.env}.json").to_s))
    end

    def default_state
      {
        "schema_version" => SCHEMA_VERSION,
        "environment" => environment,
        "state" => "not_started",
        "metadata" => {}
      }
    end

    def validate!(payload)
      raise InvalidState, "Unsupported installation state schema" unless payload["schema_version"] == SCHEMA_VERSION
      raise InvalidState, "Installation state environment mismatch" unless payload["environment"] == environment

      StateMachine.new(payload.fetch("state"))
    rescue KeyError, ArgumentError => error
      raise InvalidState, error.message
    end

    class InvalidState < StandardError; end
  end
end
