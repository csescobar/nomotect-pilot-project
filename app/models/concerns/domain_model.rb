module DomainModel
  extend ActiveSupport::Concern

  included do
    validates :organization, presence: true if reflect_on_association(:organization)
  end

  def domain_attributes
    attributes.except("created_at", "updated_at", "lock_version")
  end
end
