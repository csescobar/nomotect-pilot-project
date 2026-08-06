require "digest"

module Security
  class Throttle
    Result = Data.define(:allowed, :retry_after)

    def self.check!(scope:, identity:, limit:, period:, cache: Rails.cache)
      digest = Digest::SHA256.hexdigest(identity.to_s)
      bucket = Time.current.to_i / period.to_i
      key = "security:throttle:#{scope}:#{digest}:#{bucket}"
      count = cache.increment(key, 1, expires_in: period)
      count ||= begin
        cache.write(key, 1, expires_in: period)
        1
      end

      return Result.new(allowed: true, retry_after: 0) if count <= limit

      retry_after = period.to_i - (Time.current.to_i % period.to_i)
      ActiveSupport::Notifications.instrument("security.throttle.blocked", scope: scope, retry_after: retry_after)
      Result.new(allowed: false, retry_after: retry_after)
    end
  end
end
