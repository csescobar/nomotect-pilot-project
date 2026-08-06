module Installation
  class DatabaseConfiguration
    SCHEMA_VERSION = 1
    SSL_MODES = %w[disable allow prefer require verify-ca verify-full].freeze
    IDENTIFIER = /\A[a-z][a-z0-9_]{0,62}\z/

    ATTRIBUTES = %i[
      host port maintenance_database admin_username admin_password
      application_database application_username sslmode
    ].freeze

    def initialize(attributes)
      @attributes = attributes.to_h.symbolize_keys.slice(*ATTRIBUTES)
    end

    def validate!
      raise ArgumentError, "Database host is required" if host.blank?
      raise ArgumentError, "Database port must be between 1 and 65535" unless port.between?(1, 65_535)
      raise ArgumentError, "Maintenance database is required" if maintenance_database.blank?
      raise ArgumentError, "Administrative username is required" if admin_username.blank?
      raise ArgumentError, "Administrative password is required" if admin_password.blank?
      validate_identifier!(application_database, "Application database")
      validate_identifier!(application_username, "Application username")
      raise ArgumentError, "Unsupported PostgreSQL SSL mode" unless SSL_MODES.include?(sslmode)

      self
    end

    def connection_parameters
      {
        host: host,
        port: port,
        dbname: maintenance_database,
        user: admin_username,
        password: admin_password,
        sslmode: sslmode,
        connect_timeout: 5
      }
    end

    def public_attributes
      {
        "schema_version" => SCHEMA_VERSION,
        "host" => host,
        "port" => port,
        "maintenance_database" => maintenance_database,
        "application_database" => application_database,
        "application_username" => application_username,
        "sslmode" => sslmode
      }
    end

    ATTRIBUTES.each do |attribute|
      define_method(attribute) do
        value = @attributes[attribute]
        attribute == :port ? Integer(value || 5432, exception: false) || 0 : value.to_s.strip
      end
    end

    private

    def validate_identifier!(value, label)
      raise ArgumentError, "#{label} must start with a lowercase letter and contain only lowercase letters, numbers and underscores" unless IDENTIFIER.match?(value)
    end
  end
end
