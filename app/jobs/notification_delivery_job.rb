class NotificationDeliveryJob < ApplicationJob
  queue_as :default

  def perform(organization_id, notification_id)
    organization = Organization.find(organization_id)
    notification = organization.notifications.find(notification_id)
    TenantBoundary.assert_membership!(organization: organization, user: notification.recipient)
    return if notification.status == "delivered"

    ActiveSupport::Notifications.instrument(
      "notification.deliver.enterprise_services",
      organization_id: organization.id,
      notification_id: notification.id
    ) do
      notification.update!(status: "delivered", delivered_at: Time.current)
    end
  rescue StandardError
    notification&.update!(status: "failed")
    raise
  end
end
