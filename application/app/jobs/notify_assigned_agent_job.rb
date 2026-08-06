class NotifyAssignedAgentJob < ApplicationJob
  queue_as :default

  def perform(organization_id, service_request_id, actor_user_id)
    organization = Organization.find(organization_id)
    service_request = ServiceRequest.where(organization_id: organization.id).find(service_request_id)
    actor = TenantBoundary.resolve_member!(organization: organization, user_id: actor_user_id)

    TenantBoundary.assert_membership!(organization: organization, user: actor)
    TenantBoundary.assert_record!(organization: organization, record: service_request)

    assigned_agent = service_request.assigned_support_agent
    return unless assigned_agent

    TenantBoundary.assert_membership!(organization: organization, user: assigned_agent)

    IdempotentExecution.call(key: "notify_assigned_agent:#{service_request_id}", scope: organization.id.to_s) do
      NotificationDispatcher.call(
        organization: organization,
        kind: "service_request.assigned",
        recipient: assigned_agent,
        payload: { service_request_id: service_request.id, identifier: service_request.identifier }
      )
    end
  end
end
