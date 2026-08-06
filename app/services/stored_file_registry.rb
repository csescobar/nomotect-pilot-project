require "digest"

class StoredFileRegistry
  def self.call(organization:, uploaded_by:, name:, content_type:, bytes:)
    TenantBoundary.assert_membership!(organization: organization, user: uploaded_by)

    storage_key = [ organization.id, SecureRandom.uuid ].join("/")
    EnterpriseStorage.write(storage_key, bytes)

    StoredFile.create!(
      organization: organization,
      uploaded_by: uploaded_by,
      name: name,
      content_type: content_type,
      byte_size: bytes.bytesize,
      checksum: Digest::SHA256.hexdigest(bytes),
      storage_key: storage_key
    )
  rescue StandardError
    EnterpriseStorage.delete(storage_key) if storage_key
    raise
  end
end
