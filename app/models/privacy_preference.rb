class PrivacyPreference < ApplicationRecord
  belongs_to :organization
  belongs_to :user

  validates :purpose, presence: true, length: { maximum: 100 }
  validates :granted, inclusion: { in: [ true, false ] }
  validates :decided_at, presence: true
  validates :purpose, uniqueness: { scope: %i[organization_id user_id] }
end
