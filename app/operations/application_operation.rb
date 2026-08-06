class ApplicationOperation
  Result = Data.define(:record, :events)

  def initialize(actor: Current.user, request_id: Current.request_id)
    @actor = actor
    @request_id = request_id
  end

  private

  attr_reader :actor, :request_id

  def publish!(record, event_type, payload: {})
    DomainEvent.create!(
      organization: record.try(:organization),
      actor: actor,
      event_type: event_type,
      aggregate_type: record.class.name,
      aggregate_id: record.id,
      payload: payload,
      request_id: request_id,
      occurred_at: Time.current
    )
  end
end
