class NotificationDispatcher
  def self.call(organization:, kind:, payload: {}, recipient: nil, recipient_id: nil)
    recipient = recipient_id ? TenantBoundary.resolve_member!(organization: organization, user_id: recipient_id) : recipient
    TenantBoundary.assert_membership!(organization: organization, user: recipient)

    notification = Notification.create!(
      organization: organization,
      recipient: recipient,
      kind: kind,
      payload: payload
    )
    NotificationDeliveryJob.perform_later(organization.id, notification.id)
    notification
  end
end
