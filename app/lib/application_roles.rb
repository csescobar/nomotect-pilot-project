module ApplicationRoles
  Entry = Data.define(:key, :permissions, :protected)
  KEY = /\A[a-z][a-z0-9_]*\z/

  class Registry
    def initialize
      @entries = {}
      @sealed = false
      register(:owner, permissions: %w[platform.owner], protected: true)
      register(:admin, permissions: %w[platform.admin], protected: true)
      register(:member, permissions: [], protected: true)
    end

    def register(key, permissions:, protected: false)
      raise RuntimeError, "role registry is sealed" if sealed?

      key = key.to_s
      raise ArgumentError, "invalid role key" unless KEY.match?(key)
      raise ArgumentError, "role is already registered" if @entries.key?(key)
      permissions = Array(permissions).map(&:to_s).uniq.freeze
      raise ArgumentError, "invalid permission" unless permissions.all? { |item| item.match?(/\A[a-z][a-z0-9_.]*\z/) }
      @entries[key] = Entry.new(key, permissions, protected).freeze
    end

    def keys = @entries.keys.freeze
    def manageable_keys = keys - [ "owner" ]
    def fetch(key) = @entries.fetch(key.to_s)
    def sealed? = @sealed

    def seal!
      @entries.freeze
      @sealed = true
    end
  end

  class << self
    attr_reader :registry
    def reset! = @registry = Registry.new
    def register(...) = registry.register(...)
    def seal! = registry.seal!
    def keys = registry.keys
    def manageable_keys = registry.manageable_keys
    def permission?(role, permission) = fetch(role).permissions.include?(permission.to_s)
    def fetch(role) = registry.fetch(role)
  end
  reset!
end
