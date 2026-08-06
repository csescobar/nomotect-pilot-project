module Security
  class SecretRegistry
    REQUIRED_PRODUCTION_SECRETS = %w[SECRET_KEY_BASE].freeze
    FILTERED_KEYS = %w[password password_confirmation token secret authorization cookie webhook_secret].freeze

    def self.validate_production!
      return unless Rails.env.production?

      missing = REQUIRED_PRODUCTION_SECRETS.select { |name| ENV[name].blank? && Rails.application.credentials.public_send(name.downcase).blank? }
      raise "Missing required production secrets: #{missing.join(', ')}" if missing.any?
    end

    def self.redacted?(key)
      FILTERED_KEYS.any? { |filtered| key.to_s.downcase.include?(filtered) }
    end
  end
end
