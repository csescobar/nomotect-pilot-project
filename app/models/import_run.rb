class ImportRun < ApplicationRecord
  STATUSES = %w[pending processing completed failed].freeze

  belongs_to :organization
  belongs_to :requested_by, class_name: "User", optional: true

  validates :kind, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :processed_rows, :failed_rows, numericality: { greater_than_or_equal_to: 0 }
end
