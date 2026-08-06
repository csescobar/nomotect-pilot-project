class Customer < ApplicationRecord
  include DomainModel

  STATUSES = %w[active inactive].freeze

  belongs_to :organization

  normalizes :email_address, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :name, presence: true, length: { maximum: 120 }
  validates :email_address, length: { maximum: 320 }, allow_blank: true
  validates :status, inclusion: { in: STATUSES }

  scope :ordered, -> { order(:name, :id) }
end
