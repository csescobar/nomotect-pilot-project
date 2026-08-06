class StoredFile < ApplicationRecord
  belongs_to :organization
  belongs_to :uploaded_by, class_name: "User", optional: true

  validates :name, :content_type, :checksum, :storage_key, presence: true
  validates :byte_size, numericality: { greater_than_or_equal_to: 0 }
  validates :storage_key, uniqueness: true
end
