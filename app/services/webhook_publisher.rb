class WebhookPublisher
  def self.call(organization:, event_type:, payload:)
    organization.webhook_endpoints.find_each do |endpoint|
      next unless endpoint.subscribes_to?(event_type)

      WebhookDeliveryJob.perform_later(endpoint.id, event_type, payload)
    end
  end
end
