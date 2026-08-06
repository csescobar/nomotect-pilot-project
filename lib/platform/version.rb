# frozen_string_literal: true

require "pathname"

module Platform
  class Version
    PATTERN = /\A(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([0-9A-Za-z.-]+))?(?:\+([0-9A-Za-z.-]+))?\z/

    include Comparable

    attr_reader :value

    def self.current(path: Pathname(__dir__).join("../../VERSION").expand_path)
      new(Pathname(path).read.strip)
    end

    def initialize(value)
      @value = String(value)
      raise InvalidVersion, "platform version must use semantic versioning" unless PATTERN.match?(@value)
    end

    def <=>(other)
      Gem::Version.new(value) <=> Gem::Version.new(other.to_s)
    end

    def to_s = value

    class InvalidVersion < ArgumentError; end
  end
end
