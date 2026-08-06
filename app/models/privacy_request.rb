class PrivacyRequest < ApplicationRecord
  KINDS = %w[export anonymize].freeze
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :organization
  belongs_to :requested_by, class_name: "User"

  validates :kind, inclusion: { in: KINDS }
  validates :status, inclusion: { in: STATUSES }

  scope :pending, -> { where(status: "pending") }

  def complete!(result: {})
    update!(status: "completed", result: result, completed_at: Time.current, failure_reason: nil)
  end

  def fail!(error)
    update!(status: "failed", failure_reason: error.message.to_s.first(500))
  end
end
