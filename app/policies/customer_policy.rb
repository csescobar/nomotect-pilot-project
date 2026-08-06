class CustomerPolicy < ApplicationPolicy
  def show? = membership.present?
  def create? = membership&.admin?
  def update? = membership&.admin?
  def destroy? = membership&.admin?

  private

  def membership
    @membership ||= record.organization.membership_for(user)
  end
end
