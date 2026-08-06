class OrganizationInvitation < ApplicationRecord
  belongs_to :organization
  belongs_to :invited_by, class_name: "User"

  normalizes :email_address, with: ->(email) { email.strip.downcase }

  validates :email_address, presence: true
  validates :role, inclusion: { in: ->(_) { ApplicationRoles.manageable_keys } }
  validates :email_address, uniqueness: {
    scope: :organization_id,
    conditions: -> { where(accepted_at: nil, revoked_at: nil) }
  }
  validate :email_must_not_already_be_a_member, on: :create

  scope :pending, -> { where(accepted_at: nil, revoked_at: nil) }

  def pending? = accepted_at.nil? && revoked_at.nil?

  def acceptance_token
    signed_id(purpose: :organization_invitation, expires_in: 7.days)
  end

  def self.find_by_acceptance_token!(token)
    find_signed!(token, purpose: :organization_invitation)
  end

  def accept!(user)
    raise ActiveRecord::RecordInvalid, self unless pending?
    errors.add(:email_address, :invalid) unless user.email_address == email_address
    raise ActiveRecord::RecordInvalid, self if errors.any?

    transaction do
      organization.memberships.create!(user: user, role: role)
      update!(accepted_at: Time.current)
    end
  end

  def revoke!
    update!(revoked_at: Time.current)
  end

  private

  def email_must_not_already_be_a_member
    return unless organization&.users&.exists?(email_address: email_address)

    errors.add(:email_address, :taken)
  end
end
