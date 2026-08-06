class PlatformRole < ApplicationRecord
  ROLES = %w[platform_admin].freeze

  belongs_to :user

  validates :role, inclusion: { in: ROLES }
  validates :user_id, uniqueness: true

  def platform_admin? = role == "platform_admin"
end
