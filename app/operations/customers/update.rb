module Customers
  class Update < ApplicationOperation
    def call(customer:, attributes:)
      Customer.transaction do
        before = customer.domain_attributes
        customer.update!(attributes)
        event = publish!(customer, "customer.updated", payload: { before: before, after: customer.domain_attributes })
        Result.new(record: customer, events: [ event ])
      end
    end
  end
end
