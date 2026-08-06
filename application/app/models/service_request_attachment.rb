class ServiceRequestAttachment < ApplicationRecord
  include DomainModel

  belongs_to :organization
  belongs_to :service_request
  belongs_to :stored_file
  belongs_to :uploaded_by, class_name: "User"

  validates :stored_file_id, uniqueness: { scope: :service_request_id }
end
