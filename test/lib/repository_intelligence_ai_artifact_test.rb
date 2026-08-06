# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require_relative "../../lib/repository_intelligence/platform"
require_relative "../../lib/repository_intelligence/ai_artifact_generator"

class RepositoryIntelligenceAiArtifactTest < ActiveSupport::TestCase
  test "generates deterministic contexts and architecture reports" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}
    ))
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "test:Customer", type: "test", name: "CustomerTest", path: "test/models/customer_test.rb", properties: {}
    ))
    graph.add_edge(RepositoryIntelligence::Edge.new(
      from: "model:Customer", to: "test:Customer", type: "TESTED_BY", properties: {}
    ))

    Dir.mktmpdir do |directory|
      generator = RepositoryIntelligence::AiArtifactGenerator.new(
        repository_path: Rails.root,
        graph:,
        contracts: [ { "id" => "customer", "version" => 1 } ],
        output_directory: directory
      )

      result = generator.write

      assert File.exist?(File.join(directory, "AI_CONTEXT.md"))
      assert File.exist?(File.join(directory, "modules/customer/AI_CONTEXT.md"))
      assert File.exist?(File.join(directory, "architecture.md"))
      assert_includes result.files.fetch("impact-index.md"), "model:Customer"
      assert_empty generator.validate
    end
  end

  test "detects missing and stale generated artifacts" do
    graph = RepositoryIntelligence::GovernanceGraph.new
    graph.add_node(RepositoryIntelligence::Node.new(
      id: "model:Customer", type: "model", name: "Customer", path: "app/models/customer.rb", properties: {}
    ))

    Dir.mktmpdir do |directory|
      generator = RepositoryIntelligence::AiArtifactGenerator.new(
        repository_path: Rails.root, graph:, contracts: [], output_directory: directory
      )

      assert generator.validate.any? { |finding| finding.start_with?("missing generated artifact") }
      generator.write
      File.write(File.join(directory, "architecture.md"), "stale")
      assert_includes generator.validate, "stale generated artifact: architecture.md"
    end
  end
end
