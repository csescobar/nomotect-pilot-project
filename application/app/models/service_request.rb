class ServiceRequest < ApplicationRecord
  include DomainModel

  CATEGORIES = %w[hardware software network access other].freeze
  PRIORITIES = %w[low medium high critical].freeze

  STATUSES = %w[open triaged in_progress resolved closed].freeze
  VALID_TRANSITIONS = {
    "open" => %w[triaged in_progress closed],
    "triaged" => %w[open in_progress resolved],
    "in_progress" => %w[open resolved],
    "resolved" => %w[closed in_progress],
    "closed" => %w[open]
  }.freeze

  belongs_to :organization
  belongs_to :requester, class_name: "User"
  belongs_to :assigned_support_agent, class_name: "User", optional: true
  has_many :attachments, class_name: "ServiceRequestAttachment", dependent: :destroy

  validates :identifier, presence: true, uniqueness: { scope: :organization_id }
  validates :title, presence: true, length: { maximum: 200 }
  validates :description, presence: true, length: { maximum: 5000 }
  validates :category, inclusion: { in: CATEGORIES }
  validates :priority, inclusion: { in: PRIORITIES }
  validates :status, inclusion: { in: STATUSES }
  validate :assigned_agent_must_be_same_tenant, if: :assigned_support_agent_id
  validate :transition_must_be_allowed, on: :update

  scope :ordered, -> { order(:identifier, :id) }

  STATUSES.each do |state|
    define_method("#{state}?") { status == state }
  end

  def transition_to!(new_status)
    raise ArgumentError, "invalid status" unless STATUSES.include?(new_status)
    raise ArgumentError, "transition not allowed" unless VALID_TRANSITIONS.fetch(status).include?(new_status)

    update!(status: new_status, resolved_at: (new_status == "resolved" ? Time.current : resolved_at), closed_at: (new_status == "closed" ? Time.current : closed_at))
  end

  private

  def assigned_agent_must_be_same_tenant
    return if assigned_support_agent.nil?
    return if assigned_support_agent.memberships.exists?(organization_id: organization_id)

    errors.add(:assigned_support_agent, :not_same_tenant)
  end

  def transition_must_be_allowed
    return unless status_changed?
    return if VALID_TRANSITIONS.fetch(status_was).include?(status)

    errors.add(:status, :transition_not_allowed)
  end
end
