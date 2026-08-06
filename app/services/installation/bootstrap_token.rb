require "digest"

module Installation
  class BootstrapToken
    DEFAULT_TTL = 30.minutes

    def initialize(expected: ENV["INSTALLATION_TOKEN"], issued_at: ENV["INSTALLATION_TOKEN_ISSUED_AT"], ttl: DEFAULT_TTL)
      @expected = expected.to_s
      @issued_at = issued_at.present? ? Time.iso8601(issued_at) : nil
      @ttl = ttl
    rescue ArgumentError
      @issued_at = nil
    end

    def valid?(candidate, now: Time.current)
      return false if expected.blank? || candidate.blank? || issued_at.nil? || expired?(now)

      ActiveSupport::SecurityUtils.secure_compare(digest(candidate), digest(expected))
    end

    def configured?
      expected.present? && issued_at.present?
    end

    private

    attr_reader :expected, :issued_at, :ttl

    def expired?(now)
      now > issued_at + ttl
    end

    def digest(value)
      Digest::SHA256.hexdigest(value.to_s)
    end
  end
end
