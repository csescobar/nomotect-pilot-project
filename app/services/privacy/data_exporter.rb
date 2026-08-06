require "digest"

module Privacy
  class DataExporter
    def self.call(request:)
      TenantBoundary.assert_membership!(organization: request.organization, user: request.requested_by)

      payload = {
        generated_at: Time.current.iso8601,
        organization: { id: request.organization.id, name: request.organization.name, slug: request.organization.slug },
        user: {
          id: request.requested_by.id,
          email_address: request.requested_by.email_address,
          locale: request.requested_by.locale,
          time_zone: request.requested_by.time_zone
        },
        memberships: request.requested_by.memberships.where(organization: request.organization).map do |membership|
          { role: membership.role, created_at: membership.created_at.iso8601 }
        end,
        preferences: PrivacyPreference.where(organization: request.organization, user: request.requested_by).map do |preference|
          { purpose: preference.purpose, granted: preference.granted, decided_at: preference.decided_at.iso8601 }
        end
      }

      serialized = JSON.generate(payload)
      request.complete!(result: { payload: payload, sha256: Digest::SHA256.hexdigest(serialized) })
    end
  end
end
