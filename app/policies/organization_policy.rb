class OrganizationPolicy < ApplicationPolicy
  def show?
    membership.present?
  end

  def create?
    user.present?
  end

  def update?
    membership&.admin?
  end

  def destroy?
    membership&.owner?
  end

  def manage_members?
    membership&.admin?
  end

  def manage_owners?
    membership&.owner?
  end

  private

  def membership
    @membership ||= record.membership_for(user)
  end
end
