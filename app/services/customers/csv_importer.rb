require "csv"

module Customers
  class CsvImporter
    def self.call(organization:, requested_by:, csv:)
      TenantBoundary.assert_membership!(organization: organization, user: requested_by)

      run = ImportRun.create!(organization: organization, requested_by: requested_by, kind: "customers", status: "processing")
      operation = Customers::Create.new(actor: requested_by)

      CSV.parse(csv, headers: true).each do |row|
        operation.call(organization: organization, attributes: row.to_h.slice("name", "email_address", "status", "notes"))
        run.increment!(:processed_rows)
      rescue ActiveRecord::RecordInvalid => error
        run.increment!(:failed_rows)
        run.update!(error_details: run.error_details + [ { row: row.to_h, messages: error.record.errors.full_messages } ])
      end

      run.update!(status: run.failed_rows.zero? ? "completed" : "failed")
      run
    rescue CSV::MalformedCSVError => error
      run&.update!(status: "failed", error_details: [ { messages: [ error.message ] } ])
      raise
    end
  end
end
