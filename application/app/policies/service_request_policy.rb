class ServiceRequestPolicy < ApplicationPolicy
  def show?
    membership.present? && (membership.permitted?("service_requests.read") || record.requester_id == user.id)
  end

  def create?
    membership.present? && membership.permitted?("service_requests.create")
  end

  def update?
    membership.present? && membership.permitted?("service_requests.manage")
  end

  def assign?
    membership.present? && membership.permitted?("service_requests.assign")
  end

  def transition?
    membership.present? && membership.permitted?("service_requests.assign")
  end

  def attach_file?
    membership.present? && (membership.permitted?("service_requests.manage") || record.requester_id == user.id)
  end

  def export?
    membership.present? && membership.permitted?("service_requests.export")
  end

  def destroy?
    membership.present? && membership.permitted?("service_requests.manage")
  end

  private

  def membership
    @membership ||= record.organization.membership_for(user)
  end
end
