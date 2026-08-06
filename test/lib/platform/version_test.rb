# frozen_string_literal: true

require "test_helper"

class PlatformVersionTest < ActiveSupport::TestCase
  test "reads the canonical repository version" do
    assert_equal Rails.root.join("VERSION").read.strip, Platform::Version.current.to_s
  end

  test "rejects non-semantic versions" do
    assert_raises(Platform::Version::InvalidVersion) { Platform::Version.new("release-eight") }
  end
end
