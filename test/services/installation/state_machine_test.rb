require "test_helper"
require "tmpdir"

class Installation::StateMachineTest < ActiveSupport::TestCase
  test "allows only declared transitions" do
    machine = Installation::StateMachine.new("not_started")

    assert_equal "appearance", machine.transition_to("appearance").state
    assert_raises(Installation::StateMachine::InvalidTransition) { machine.transition_to("database") }
  end

  test "completed state is terminal" do
    machine = Installation::StateMachine.new("completed")

    assert machine.completed?
    assert_raises(Installation::StateMachine::InvalidTransition) { machine.transition_to("appearance") }
  end

  test "state store writes atomically and validates the environment" do
    Dir.mktmpdir do |directory|
      path = Pathname(directory).join("state.json")
      store = Installation::StateStore.new(path: path, environment: "test")

      payload = store.write!(state: "appearance", metadata: { "installation_id" => "example" })

      assert_equal "appearance", payload.fetch("state")
      assert_equal "appearance", store.read.fetch("state")
      assert_equal "example", store.read.dig("metadata", "installation_id")
      assert_raises(Installation::StateStore::InvalidState) do
        Installation::StateStore.new(path: path, environment: "production").read
      end
    end
  end

  test "bootstrap token is time limited and compared securely" do
    issued_at = Time.current.change(usec: 0)
    token = Installation::BootstrapToken.new(expected: "secret", issued_at: issued_at.iso8601, ttl: 5.minutes)

    assert token.valid?("secret", now: issued_at + 4.minutes)
    refute token.valid?("wrong", now: issued_at + 4.minutes)
    refute token.valid?("secret", now: issued_at + 6.minutes)
  end

  test "wizard maps states to registered paths" do
    wizard = Installation::Wizard.new

    assert_equal "/installation/appearance", wizard.path_for("not_started")
    assert_equal "/installation/database", wizard.path_for("database")
    assert_raises(Installation::Wizard::UnknownStep) { wizard.step("unknown") }
  end
end
