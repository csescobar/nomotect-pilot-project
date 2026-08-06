require "json"

module Installation
  class AppearanceStore
    SCHEMA_VERSION = 1

    def initialize(path: default_path, environment: Rails.env)
      @path = Pathname(path)
      @environment = environment.to_s
    end

    attr_reader :path, :environment

    def read
      return defaults unless path.exist?

      payload = JSON.parse(path.read)
      raise ArgumentError, "Unsupported appearance schema" unless payload["schema_version"] == SCHEMA_VERSION
      raise ArgumentError, "Appearance environment mismatch" unless payload["environment"] == environment

      defaults.merge(payload)
    rescue JSON::ParserError => error
      raise ArgumentError, "Invalid appearance JSON: #{error.message}"
    end

    def write!(attributes)
      payload = defaults.merge(attributes.stringify_keys).merge(
        "schema_version" => SCHEMA_VERSION,
        "environment" => environment,
        "updated_at" => Time.current.utc.iso8601
      )
      path.dirname.mkpath
      temporary = path.sub_ext("#{path.extname}.tmp")
      temporary.write(JSON.pretty_generate(payload) + "\n")
      File.rename(temporary, path)
      payload
    ensure
      temporary&.delete if temporary&.exist?
    end

    private

    def default_path
      Pathname(ENV.fetch("INSTALLATION_APPEARANCE_PATH", Rails.root.join("var/installation/appearance.#{Rails.env}.json").to_s))
    end

    def defaults
      {
        "schema_version" => SCHEMA_VERSION,
        "environment" => environment,
        "application_name" => "Rails Hotwire Platform",
        "default_locale" => "en",
        "supported_locales" => %w[en pt-BR],
        "trademark_mode" => "name_only",
        "logo_path" => nil,
        "compact_logo_path" => nil,
        "favicon_path" => nil
      }
    end
  end
end
