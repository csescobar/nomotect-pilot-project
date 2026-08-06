class RetentionEnforcementJob < ApplicationJob
  queue_as :default

  def perform(organization_id)
    organization = Organization.find(organization_id)

    RetentionPolicy.where(organization: organization, enabled: true).find_each do |policy|
      model = policy.record_type.safe_constantize
      next unless model && model.column_names.include?("organization_id") && model.column_names.include?("created_at")

      cutoff = policy.retention_days.days.ago
      model.where(organization_id: organization.id).where("created_at < ?", cutoff).find_each(&:destroy!)
    end
  end
end
