class DomainEvent < ApplicationRecord
  belongs_to :organization, optional: true
  belongs_to :actor, class_name: "User", optional: true

  validates :event_type, :aggregate_type, :aggregate_id, :occurred_at, presence: true

  scope :recent_first, -> { order(occurred_at: :desc, id: :desc) }
end
