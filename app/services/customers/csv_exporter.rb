require "csv"

module Customers
  class CsvExporter
    def self.call(user:, organization:)
      TenantBoundary.assert_membership!(organization: organization, user: user)

      customers = VisibleTo.new(user: user, organization: organization).call
      CSV.generate(headers: true) do |csv|
        csv << %w[id name email_address status updated_at]
        customers.each do |customer|
          TenantBoundary.assert_record!(organization: organization, record: customer)
          csv << [ customer.id, customer.name, customer.email_address, customer.status, customer.updated_at.iso8601 ]
        end
      end
    end
  end
end
