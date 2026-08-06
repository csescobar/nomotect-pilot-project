# frozen_string_literal: true

require "json"

module Releases
  module CanonicalJson
    module_function

    def generate(value)
      JSON.generate(normalize(value))
    end

    def normalize(value)
      case value
      when Hash
        value.to_h { |key, item| [ key.to_s, normalize(item) ] }.sort.to_h
      when Array
        value.map { |item| normalize(item) }
      else
        value
      end
    end
  end
end
