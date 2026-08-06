class FeatureFlag < ApplicationRecord
  belongs_to :organization, optional: true

  validates :key, presence: true, uniqueness: { scope: :organization_id }

  def self.active_for?(key, organization: nil)
    scoped = find_by(key: key, organization: organization)
    return scoped.enabled? if scoped

    find_by(key: key, organization: nil)&.enabled? || false
  end
end
