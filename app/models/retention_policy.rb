class RetentionPolicy < ApplicationRecord
  SUPPORTED_RECORD_TYPES = %w[Notification ImportRun ExportRun AuditEvent DomainEvent].freeze

  belongs_to :organization

  validates :record_type, inclusion: { in: SUPPORTED_RECORD_TYPES }
  validates :record_type, uniqueness: { scope: :organization_id }
  validates :retention_days, numericality: { only_integer: true, greater_than: 0 }
end
