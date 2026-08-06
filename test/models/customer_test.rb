require "test_helper"

class CustomerTest < ActiveSupport::TestCase
  setup do
    @organization = Organization.create!(name: "Acme")
  end

  test "validates status and required name" do
    customer = @organization.customers.new(name: "", status: "unknown")

    assert_not customer.valid?
    assert customer.errors[:name].any?
    assert customer.errors[:status].any?
  end

  test "normalizes email address" do
    customer = @organization.customers.create!(name: "Ada", email_address: " ADA@EXAMPLE.COM ")

    assert_equal "ada@example.com", customer.email_address
  end

  test "uses optimistic locking" do
    customer = @organization.customers.create!(name: "Ada")
    stale = Customer.find(customer.id)
    customer.update!(name: "Grace")

    assert_raises(ActiveRecord::StaleObjectError) { stale.update!(name: "Linus") }
  end
end
