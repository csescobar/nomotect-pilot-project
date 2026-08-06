# frozen_string_literal: true

require "test_helper"
require "json"
require "pathname"

class McpBootstrapTest < ActiveSupport::TestCase
  ROOT = Pathname(__dir__).join("../..").expand_path
  SERVER_NAME = "nomotect-repository-intelligence"

  test "MCP client configurations are portable and read-only" do
    [ ".mcp.json", ".agents/mcp_config.json" ].each do |relative_path|
      server = JSON.parse(ROOT.join(relative_path).read).fetch("mcpServers").fetch(SERVER_NAME)
      serialized = JSON.generate(server)

      assert_equal "false", server.dig("env", "MCP_ALLOW_WRITES")
      assert_equal "null", server.dig("env", "CODE_GRAPH_PROVIDER")
      assert_equal "ruby", server.fetch("command")
      assert_equal [ "bin/nomotect-mcp" ], server.fetch("args")
      assert_includes serialized, "bin/nomotect-mcp"
      refute_match %r{/(home|Users)/}, serialized
      refute_includes serialized, "bash"
    end
  end

  test "bootstrap documentation enforces the two-session restart gate" do
    bootstrap = ROOT.join("MCP_BOOTSTRAP.md").read
    setup = ROOT.join("docs/ai/mcp-setup.md").read

    assert_includes bootstrap, "Session A"
    assert_includes bootstrap, "Session B"
    assert_includes bootstrap, "restart Antigravity CLI"
    assert_includes setup, "RESTART_REQUIRED"
    assert_includes setup, "A local shell invocation is not evidence"
  end

  test "portable wrapper fails closed when writes are requested" do
    wrapper = ROOT.join("bin/nomotect-mcp").read

    assert_includes wrapper, 'ENV["MCP_ALLOW_WRITES"] = "false"'
    assert_includes wrapper, 'ENV.fetch("MCP_ALLOW_WRITES", "false") == "false"'
    assert_includes wrapper, "Repository Intelligence runtime was not found"
    refute_includes wrapper, "VISION.md"
    refute_includes wrapper, "git rev-parse"
  end
end
