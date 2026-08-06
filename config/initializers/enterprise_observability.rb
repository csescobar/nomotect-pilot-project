ActiveSupport::Notifications.subscribe(/\.enterprise_services\z/) do |name, started, finished, unique_id, payload|
  Rails.logger.info(
    event: name,
    event_id: unique_id,
    duration_ms: ((finished - started) * 1000).round(2),
    request_id: Current.request_id,
    organization_id: Current.respond_to?(:organization) ? Current.organization&.id : nil,
    payload_keys: payload.keys.map(&:to_s).sort
  )
end
