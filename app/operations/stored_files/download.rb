module StoredFiles
  class Download < ApplicationOperation
    Payload = Data.define(:bytes, :name, :content_type)

    def call(organization:, stored_file:)
      TenantBoundary.assert_membership!(organization: organization, user: actor)
      TenantBoundary.assert_record!(organization: organization, record: stored_file)

      Payload.new(
        bytes: EnterpriseStorage.read(stored_file.storage_key),
        name: stored_file.name,
        content_type: stored_file.content_type
      )
    end
  end
end
