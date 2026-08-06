class IdempotencyRecord < ApplicationRecord
  STATUSES = %w[started completed failed].freeze

  validates :key, :scope, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :key, uniqueness: { scope: :scope }

  scope :expired, -> { where(expires_at: ...Time.current) }
end
