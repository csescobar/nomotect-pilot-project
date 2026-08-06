class TenantBoundary
  class Violation < StandardError; end

  def self.assert_membership!(organization:, user:)
    membership = organization.memberships.find_by(user: user)
    raise Violation, "user is not a member of the tenant" unless membership

    membership
  end

  def self.resolve_member!(organization:, user_id:)
    membership = organization.memberships.includes(:user).find_by(user_id: user_id)
    raise Violation, "user is not a member of the tenant" unless membership

    membership.user
  end

  def self.assert_record!(organization:, record:)
    record_organization_id = record.respond_to?(:organization_id) ? record.organization_id : nil
    raise Violation, "record does not belong to the tenant" unless record_organization_id == organization.id

    record
  end

  def self.assert_same_tenant!(*records, organization:)
    records.compact.each { |record| assert_record!(organization: organization, record: record) }
    true
  end
end
