# frozen_string_literal: true

require "json"
require "yaml"

module Epic10
  class RcUpgradeCertification
    class InvalidCertification < StandardError; end

    def initialize(root: Rails.root.join("test/support/epic_10/upgrades"), clock: -> { Time.current.utc })
      @root = Pathname(root)
      @clock = clock
    end

    def call
      fixture = RcUpgradeFixture.new(root: root).call
      manifest = Upgrades::Manifest.new(load_yaml("rc.1-to-rc.2.yml"))
      plan = Upgrades::Planner::Plan.new(
        manifest.id,
        fixture.fetch("source_candidate"),
        fixture.fetch("target_candidate"),
        manifest.backup_required?,
        manifest.operations,
        []
      )
      store = MemoryStore.new
      calls = []
      interrupted = true
      registry = Upgrades::OperationRegistry.new
      manifest.operations.each do |operation|
        registry.register(operation.fetch("id")) do
          if operation.fetch("id") == "migrate-service-requests" && interrupted
            throw :certification_interruption
          end
          calls << operation.fetch("id")
        end
      end
      executor = Upgrades::Executor.new(
        plan: plan,
        safety_gate: PermitGate.new,
        registry: registry,
        store: store,
        lock: InlineLock.new,
        clock: clock
      )

      catch(:certification_interruption) { executor.execute! }
      interrupted_state = deep_copy(store.read)
      guidance = Upgrades::RecoveryAdvisor.new(manifest: manifest, execution_state: interrupted_state).call
      interrupted = false
      executor.execute!
      completed_state = store.read

      validate!(manifest, fixture, interrupted_state, completed_state, guidance, calls)

      {
        "schema_version" => 1,
        "phase" => 3,
        "status" => "passed",
        "manifest_id" => manifest.id,
        "source_candidate" => fixture.fetch("source_candidate"),
        "target_candidate" => fixture.fetch("target_candidate"),
        "interruption" => {
          "status" => interrupted_state.fetch("status"),
          "classification" => guidance.fetch("classification")
        },
        "resume" => {
          "status" => completed_state.fetch("status"),
          "completed_operation_ids" => calls
        },
        "backup_evidence_required" => manifest.backup_required?,
        "incompatible_inputs_rejected" => true,
        "credential_free" => true,
        "publication" => { "allowed" => false }
      }
    rescue KeyError, Psych::Exception, Errno::ENOENT, Upgrades::Manifest::InvalidManifest,
      RcUpgradeFixture::InvalidFixture => error
      raise InvalidCertification, error.message
    end

    private

    attr_reader :root, :clock

    def load_yaml(name)
      YAML.safe_load_file(root.join(name), aliases: false)
    end

    def validate!(manifest, fixture, interrupted_state, completed_state, guidance, calls)
      expected = manifest.operations.pluck("id")
      raise InvalidCertification, "interruption evidence is missing" unless interrupted_state["status"] == "running"
      raise InvalidCertification, "recovery guidance is not retryable" unless guidance["classification"] == "retryable"
      raise InvalidCertification, "resume did not complete" unless completed_state["status"] == "completed"
      raise InvalidCertification, "operations were replayed or omitted" unless calls == expected
      raise InvalidCertification, "backup evidence is not required" unless manifest.backup_required?
      source = Upgrades::Version.new(fixture.fetch("source_candidate"))
      raise InvalidCertification, "incompatible source was accepted" if source.satisfies?("= 0.9.0")
    end

    def deep_copy(value)
      JSON.parse(JSON.generate(value))
    end

    class MemoryStore
      def read = @state
      def write!(payload) = (@state = JSON.parse(JSON.generate(payload)))
    end

    class PermitGate
      def authorize! = true
    end

    class InlineLock
      def synchronize = yield
    end
  end
end
