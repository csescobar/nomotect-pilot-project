# frozen_string_literal: true

require "test_helper"

module OperationalReadiness
  class DisasterRecoveryPolicyTest < ActiveSupport::TestCase
    test "certifies the example and blocks incomplete objectives" do
      policy = DisasterRecoveryPolicy.load(Rails.root.join("config/operations/disaster-recovery.example.json"))
      assert policy.readiness.fetch("ready")

      data = JSON.parse(JSON.generate(policy.data))
      data["objectives"]["rto_minutes"] = nil
      refute DisasterRecoveryPolicy.new(data).readiness.fetch("ready")
    end
  end
end
