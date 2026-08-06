class CustomerExportJob < ApplicationJob
  queue_as :default

  def perform(organization_id:, requested_by_id:, idempotency_key:)
    organization = Organization.find(organization_id)
    user = TenantBoundary.resolve_member!(organization: organization, user_id: requested_by_id)

    IdempotentExecution.call(key: idempotency_key, scope: "customer-export:#{organization_id}") do
      csv = Customers::CsvExporter.call(user: user, organization: organization)
      file = StoredFileRegistry.call(
        organization: organization,
        uploaded_by: user,
        name: "customers-#{Time.current.to_date.iso8601}.csv",
        content_type: "text/csv",
        bytes: csv
      )
      { "stored_file_id" => file.id }
    end
  end
end
