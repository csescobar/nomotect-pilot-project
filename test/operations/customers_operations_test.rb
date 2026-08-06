require "test_helper"

class CustomersOperationsTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email_address: "owner@example.com", password: "a-secure-password")
    @organization = Organization.create!(name: "Acme")
    @organization.memberships.create!(user: @user, role: "owner")
  end

  test "create persists customer and domain event atomically" do
    result = nil

    assert_difference [ "Customer.count", "DomainEvent.count" ], 1 do
      result = Customers::Create.new(actor: @user, request_id: "request-1").call(
        organization: @organization,
        attributes: { name: "Ada", email_address: "ada@example.com", status: "active" }
      )
    end

    assert_equal "customer.created", result.events.first.event_type
    assert_equal result.record.id, result.events.first.aggregate_id
    assert_equal "request-1", result.events.first.request_id
  end

  test "update records before and after state" do
    customer = @organization.customers.create!(name: "Ada")

    result = Customers::Update.new(actor: @user).call(customer: customer, attributes: { name: "Grace" })

    assert_equal "Ada", result.events.first.payload.dig("before", "name")
    assert_equal "Grace", result.events.first.payload.dig("after", "name")
  end

  test "destroy preserves an audit event" do
    customer = @organization.customers.create!(name: "Ada")

    assert_difference "Customer.count", -1 do
      assert_difference "DomainEvent.count", 1 do
        Customers::Destroy.new(actor: @user).call(customer: customer)
      end
    end

    assert_equal "customer.deleted", DomainEvent.last.event_type
  end
end
