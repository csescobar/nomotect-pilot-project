module GridEngine
  class Registry
    class UnknownKeyError < KeyError; end

    def initialize
      @entries = {}
    end

    def register(key, value = nil, &block)
      normalized = key.to_s
      @entries[normalized] = value || block
      self
    end

    def fetch(key)
      @entries.fetch(key.to_s) { raise UnknownKeyError, "Unknown registry key: #{key}" }
    end

    def key?(key) = @entries.key?(key.to_s)
    def keys = @entries.keys.freeze
  end
end
