class WorkflowTransition
  InvalidTransition = Class.new(StandardError)

  def self.call(record:, attribute:, to:, allowed:, actor: Current.user)
    current = record.public_send(attribute)
    destinations = allowed.fetch(current.to_s, [])
    raise InvalidTransition, "#{current} cannot transition to #{to}" unless destinations.include?(to.to_s)

    record.transaction do
      record.update!(attribute => to)
      DomainEvent.create!(
        organization: record.try(:organization),
        actor: actor,
        event_type: "#{record.class.model_name.singular}.transitioned",
        aggregate_type: record.class.name,
        aggregate_id: record.id,
        payload: { attribute: attribute, from: current, to: to },
        request_id: Current.request_id,
        occurred_at: Time.current
      )
    end
    record
  end
end
