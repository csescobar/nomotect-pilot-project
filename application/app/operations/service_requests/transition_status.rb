module ServiceRequests
  class TransitionStatus < ApplicationOperation
    def call(service_request:, new_status:)
      ServiceRequest.transaction do
        TenantBoundary.assert_record!(organization: service_request.organization, record: service_request)
        before = service_request.domain_attributes
        service_request.transition_to!(new_status)
        event = publish!(service_request, "service_request.status_changed",
          payload: { before: before, after: service_request.domain_attributes })
        Result.new(record: service_request, events: [ event ])
      end
    end
  end
end
