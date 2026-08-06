# frozen_string_literal: true

module Extensions
  class Registry
    Entry = Data.define(:id, :version, :capabilities, :hooks) do
      def to_h
        {
          id: id,
          version: version,
          capabilities: capabilities.keys.sort,
          hooks: hooks.keys.map(&:to_s).sort
        }
      end
    end

    def initialize
      @entries = {}
      @sealed = false
    end

    def register(package, id)
      raise RegistrySealed, "extension registry is sealed" if sealed?
      raise IdentityMismatch, "registration id must match the extension manifest" unless id == package.id
      raise DuplicateRegistration, "extension is already registered" if registered?(id)

      registration = Registration.new(package)
      yield registration
      entry = registration.finish
      duplicate = entry.capabilities.keys.find { |capability| capability_registered?(capability) }
      raise DuplicateCapability, "capability is already registered" if duplicate

      entries[id] = entry
      entry
    end

    def fetch(id) = entries.fetch(id)
    def registered?(id) = entries.key?(id)
    def registered_ids = entries.keys.sort.freeze
    def sealed? = @sealed

    def seal!
      entries.each_value do |entry|
        entry.capabilities.freeze
        entry.hooks.freeze
        entry.freeze
      end
      entries.freeze
      @sealed = true
      freeze
    end

    def to_h
      {
        sealed: sealed?,
        extensions: entries.keys.sort.map { |id| entries.fetch(id).to_h }
      }
    end

    private

    attr_reader :entries

    def capability_registered?(id)
      entries.each_value.any? { |entry| entry.capabilities.key?(id) }
    end

    class Registration
      COMPONENT_HOOKS = %i[configuration migrations routes assets documentation].freeze

      def initialize(package)
        @package = package
        @capabilities = {}
        @hooks = {}
      end

      def capability(id, version:, provider:)
        declaration = package.manifest.provided_capabilities.find { |item| item.fetch("id") == id }
        raise UndeclaredCapability, "capability is not declared by the extension manifest" unless declaration
        unless declaration.fetch("version") == version
          raise CapabilityVersionMismatch, "capability version must match the extension manifest"
        end
        raise DuplicateCapability, "capability is already registered" if capabilities.key?(id)
        raise InvalidProvider, "capability provider must respond to call" unless provider.respond_to?(:call)

        capabilities[id] = {
          version: version,
          provider: provider
        }.freeze
      end

      COMPONENT_HOOKS.each do |name|
        define_method(name) do |callable = nil, &block|
          register_hook(name, callable || block)
        end
      end

      def finish
        missing = package.manifest.provided_capabilities.pluck("id") - capabilities.keys
        raise MissingCapability, "declared capabilities must be registered" if missing.any?

        Entry.new(
          package.id,
          package.version,
          capabilities.dup,
          hooks.dup
        )
      end

      private

      attr_reader :package, :capabilities, :hooks

      def register_hook(name, callable)
        raise UndeclaredHook, "component hook is not declared by the extension manifest" unless hook_declared?(name)
        raise DuplicateHook, "component hook is already registered" if hooks.key?(name)
        raise InvalidProvider, "component hook must respond to call" unless callable.respond_to?(:call)

        hooks[name] = callable
      end

      def hook_declared?(name)
        components = package.manifest.components
        case name
        when :configuration, :documentation
          components.fetch(name.to_s).present?
        when :migrations
          components.dig("migrations", "paths").any?
        else
          components.key?(name.to_s)
        end
      end
    end

    class RegistryError < StandardError; end
    class RegistrySealed < RegistryError; end
    class IdentityMismatch < RegistryError; end
    class DuplicateRegistration < RegistryError; end
    class MissingRegistration < RegistryError; end
    class UndeclaredCapability < RegistryError; end
    class CapabilityVersionMismatch < RegistryError; end
    class DuplicateCapability < RegistryError; end
    class MissingCapability < RegistryError; end
    class UndeclaredHook < RegistryError; end
    class DuplicateHook < RegistryError; end
    class InvalidProvider < RegistryError; end
  end
end
