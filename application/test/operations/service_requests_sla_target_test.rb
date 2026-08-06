require "test_helper"

class ServiceRequestsSlaTargetTest < ActiveSupport::TestCase
  test "resolves a deterministic SLA target for each priority" do
    result = ServiceRequests::SlaTarget.call(priority: "critical")

    assert result[:deterministic]
    assert_equal "critical", result[:priority]
    assert_equal 4.hours.to_i, result[:target_seconds]
  end

  test "high priority resolves to twenty-four hours" do
    result = ServiceRequests::SlaTarget.call(priority: "high")

    assert_equal 24.hours.to_i, result[:target_seconds]
  end

  test "unknown priorities fall back to the default target" do
    result = ServiceRequests::SlaTarget.call(priority: "bogus")

    assert_equal 24.hours.to_i, result[:target_seconds]
  end

  test "every declared priority has a documented target" do
    ServiceRequest::PRIORITIES.each do |priority|
      result = ServiceRequests::SlaTarget.call(priority: priority)
      assert result[:target_seconds].positive?, "missing SLA target for #{priority}"
      assert result[:deterministic], "SLA target for #{priority} must be deterministic"
    end
  end
end
