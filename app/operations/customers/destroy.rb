module Customers
  class Destroy < ApplicationOperation
    def call(customer:)
      Customer.transaction do
        payload = customer.domain_attributes
        event = publish!(customer, "customer.deleted", payload: payload)
        customer.destroy!
        Result.new(record: customer, events: [ event ])
      end
    end
  end
end
