module ServiceRequests
  class Update < ApplicationOperation
    def call(service_request:, attributes:)
      ServiceRequest.transaction do
        TenantBoundary.assert_record!(organization: service_request.organization, record: service_request)
        before = service_request.domain_attributes
        service_request.update!(attributes)
        event = publish!(service_request, "service_request.updated",
          payload: { before: before, after: service_request.domain_attributes })
        Result.new(record: service_request, events: [ event ])
      end
    end
  end
end
