class CustomerImportJob < ApplicationJob
  queue_as :default

  def perform(organization_id:, requested_by_id:, csv:, idempotency_key:)
    organization = Organization.find(organization_id)
    user = TenantBoundary.resolve_member!(organization: organization, user_id: requested_by_id)

    IdempotentExecution.call(key: idempotency_key, scope: "customer-import:#{organization_id}") do
      run = Customers::CsvImporter.call(
        organization: organization,
        requested_by: user,
        csv: csv
      )
      { "import_run_id" => run.id, "status" => run.status }
    end
  end
end
