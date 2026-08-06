# frozen_string_literal: true

require "rubygems"

module Upgrades
  class Version
    PATTERN = /\A(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*)(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?\z/

    include Comparable

    attr_reader :value

    def initialize(value)
      @value = String(value)
      raise ArgumentError, "invalid semantic version: #{@value}" unless PATTERN.match?(@value)

      @gem_version = Gem::Version.new(@value.split("+").first)
    end

    def <=>(other)
      gem_version <=> self.class.new(other.to_s).send(:gem_version)
    end

    def satisfies?(requirement)
      constraints = String(requirement).split(",").map(&:strip)
      raise ArgumentError, "invalid version requirement: #{requirement}" if constraints.empty? || constraints.any?(&:empty?)

      Gem::Requirement.new(*constraints).satisfied_by?(gem_version)
    rescue Gem::Requirement::BadRequirementError
      raise ArgumentError, "invalid version requirement: #{requirement}"
    end

    def to_s
      value
    end

    protected

    attr_reader :gem_version
  end
end
