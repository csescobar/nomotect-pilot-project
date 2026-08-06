module Installation
  class RuntimeDatabaseConfiguration
    REQUIRED_KEYS = %w[
      DATABASE_HOST DATABASE_PORT DATABASE_NAME DATABASE_USERNAME DATABASE_PASSWORD DATABASE_SSLMODE
    ].freeze

    def initialize(path: Rails.root.join("var/installation/runtime.#{Rails.env}.env"))
      @path = Pathname(path)
    end

    def to_h
      values = parse
      missing = REQUIRED_KEYS.reject { |key| values[key].present? }
      raise ArgumentError, "Runtime database configuration is incomplete" if missing.any?

      {
        adapter: "postgresql",
        host: values.fetch("DATABASE_HOST"),
        port: Integer(values.fetch("DATABASE_PORT")),
        database: values.fetch("DATABASE_NAME"),
        username: values.fetch("DATABASE_USERNAME"),
        password: values.fetch("DATABASE_PASSWORD"),
        sslmode: values.fetch("DATABASE_SSLMODE"),
        pool: 1,
        checkout_timeout: 5
      }
    end

    private

    attr_reader :path

    def parse
      raise ArgumentError, "Runtime database secret file is missing" unless path.exist?

      path.each_line.each_with_object({}) do |line, values|
        key, raw = line.strip.split("=", 2)
        next if key.blank? || raw.blank?

        values[key] = unescape(raw)
      end
    end

    def unescape(raw)
      value = raw.start_with?('"') && raw.end_with?('"') ? raw[1..-2] : raw
      value.gsub("\\n", "\n").gsub('\\"', '"').gsub("\\\\", "\\")
    end
  end
end
