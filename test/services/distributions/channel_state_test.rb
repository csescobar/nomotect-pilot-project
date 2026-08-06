# frozen_string_literal: true

require "test_helper"

module Distributions
  class ChannelStateTest < ActiveSupport::TestCase
    test "accepts a credential-free absent channel observation" do
      state = ChannelState.new(state_data)

      assert_equal "github_release", state.channel
      assert_equal "absent", state.status
      assert_nil state.observed_commit
    end

    test "rejects unsupported channel observation fields" do
      data = state_data.merge("authorization" => "secret")

      error = assert_raises(ChannelState::InvalidState) { ChannelState.new(data) }
      assert_includes error.message, "unsupported keys"
    end

    test "rejects malformed observed commits" do
      data = state_data.merge("observed_commit" => "main")

      error = assert_raises(ChannelState::InvalidState) { ChannelState.new(data) }
      assert_includes error.message, "invalid format"
    end

    private

    def state_data
      {
        "schema_version" => 1,
        "channel" => "github_release",
        "repository" => "owner/platform",
        "version" => "0.8.0",
        "tag" => "v0.8.0",
        "status" => "absent",
        "immutable_reference" => nil,
        "observed_commit" => nil,
        "findings" => []
      }
    end
  end
end
