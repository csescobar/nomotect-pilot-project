# frozen_string_literal: true

require "test_helper"

module Upgrades
  class VersionTest < ActiveSupport::TestCase
    test "compares semantic versions" do
      assert_operator Version.new("1.2.0"), :>, Version.new("1.1.9")
      assert_equal Version.new("1.2.0"), Version.new("1.2.0+build.7")
    end

    test "evaluates version requirements" do
      assert Version.new("1.4.2").satisfies?(">= 1.2, < 2.0")
      assert_not Version.new("2.0.0").satisfies?("~> 1.4")
    end

    test "rejects invalid versions" do
      assert_raises(ArgumentError) { Version.new("1.2") }
      assert_raises(ArgumentError) { Version.new("v1.2.3") }
    end
  end
end
