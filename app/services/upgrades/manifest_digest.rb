# frozen_string_literal: true

require "digest"
require "json"

module Upgrades
  class ManifestDigest
    def self.call(manifest)
      Digest::SHA256.hexdigest(JSON.generate(canonical(manifest.data)))
    end

    def self.canonical(value)
      case value
      when Hash
        value.keys.sort.to_h { |key| [ key, canonical(value.fetch(key)) ] }
      when Array
        value.map { |item| canonical(item) }
      else
        value
      end
    end

    private_class_method :canonical
  end
end
