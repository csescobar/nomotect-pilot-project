class Current < ActiveSupport::CurrentAttributes
  attribute :session, :request_id, :correlation_id, :locale, :organization, :membership

  delegate :user, to: :session, allow_nil: true

  def organization=(organization)
    super
    self.membership = organization&.membership_for(user)
  end

  def tenant?
    organization.present? && membership.present?
  end

  def require_tenant!
    return self if tenant?

    raise ActiveRecord::RecordNotFound, "active tenant not available"
  end

  resets do
    Time.zone = "UTC"
  end
end
