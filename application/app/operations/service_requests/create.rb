module ServiceRequests
  class Create < ApplicationOperation
    def call(organization:, attributes:, requester: actor)
      ServiceRequest.transaction do
        membership = TenantBoundary.assert_membership!(organization: organization, user: requester)
        next_identifier = next_identifier(organization)

        record = ServiceRequest.create!(
          attributes.merge(identifier: next_identifier, requester: requester, organization: organization)
        )
        event = publish!(record, "service_request.created",
          payload: record.domain_attributes.merge(requester_role: membership.role))
        Result.new(record: record, events: [ event ])
      end
    end

    private

    def next_identifier(organization)
      latest = ServiceRequest.where(organization_id: organization.id).order(created_at: :desc, id: :desc).first
      sequence = latest ? latest.identifier[/\A\d+\z/].to_i + 1 : 1
      format("%08d", sequence)
    end
  end
end
