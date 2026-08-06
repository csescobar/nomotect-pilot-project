require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email addresses" do
    user = User.new(email_address: "  USER@Example.COM ", password: "a-secure-password")
    user.validate

    assert_equal "user@example.com", user.email_address
  end

  test "requires a sufficiently long password" do
    user = User.new(email_address: "user@example.com", password: "short")

    assert_not user.valid?
    assert user.errors.added?(:password, :too_short, count: 12)
  end
end
