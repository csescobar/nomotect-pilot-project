class StoredFilePolicy < ApplicationPolicy
  def show? = membership.present?

  private

  def membership
    @membership ||= record.organization.membership_for(user)
  end
end
