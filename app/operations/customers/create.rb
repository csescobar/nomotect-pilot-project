module Customers
  class Create < ApplicationOperation
    def call(organization:, attributes:)
      Customer.transaction do
        customer = organization.customers.create!(attributes)
        event = publish!(customer, "customer.created", payload: customer.domain_attributes)
        Result.new(record: customer, events: [ event ])
      end
    end
  end
end
