class Notification < ApplicationRecord
  STATUSES = %w[pending delivered failed].freeze

  belongs_to :organization
  belongs_to :recipient, class_name: "User"

  validates :kind, presence: true
  validates :status, inclusion: { in: STATUSES }
end
