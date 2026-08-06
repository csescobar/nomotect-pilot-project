module Customers
  class VisibleTo
    def initialize(user:, organization:)
      @user = user
      @organization = organization
    end

    def call
      return Customer.none unless @organization.membership_for(@user)

      @organization.customers.ordered
    end
  end
end
