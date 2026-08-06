module Privacy
  class Anonymizer
    def self.call(request:)
      TenantBoundary.assert_membership!(organization: request.organization, user: request.requested_by)

      ApplicationRecord.transaction do
        PrivacyPreference.where(organization: request.organization, user: request.requested_by).delete_all
        request.organization.customers.where(email_address: request.requested_by.email_address).find_each do |customer|
          customer.update!(
            name: "Anonymized customer",
            email_address: "anonymized-#{customer.id}@invalid.example",
            status: "inactive"
          )
        end

        request.complete!(result: { anonymized_at: Time.current.iso8601 })
      end
    end
  end
end
