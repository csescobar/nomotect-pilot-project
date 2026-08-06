module Authorization
  extend ActiveSupport::Concern

  included do
    helper_method :allowed_to?
  end

  private

  def authorize!(record, query)
    raise ApplicationPolicy::NotAuthorizedError unless allowed_to?(record, query)

    true
  end

  def allowed_to?(record, query)
    policy_for(record).public_send(query)
  end

  def policy_for(record)
    policy_class = "#{record.class.name}Policy".constantize
    policy_class.new(Current.user, record)
  end
end
