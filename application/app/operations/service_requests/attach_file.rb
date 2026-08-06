module ServiceRequests
  class AttachFile < ApplicationOperation
    def call(service_request:, name:, content_type:, bytes:)
      ServiceRequest.transaction do
        organization = service_request.organization
        TenantBoundary.assert_membership!(organization: organization, user: actor)
        TenantBoundary.assert_record!(organization: organization, record: service_request)

        storage_key = "#{organization.id}/#{SecureRandom.uuid}"
        EnterpriseStorage.write(storage_key, bytes)
        stored_file = organization.stored_files.create!(
          name: name,
          content_type: content_type,
          byte_size: bytes.bytesize,
          checksum: Digest::SHA256.hexdigest(bytes),
          storage_key: storage_key,
          uploaded_by: actor
        )
        attachment = ServiceRequestAttachment.create!(
          organization: organization,
          service_request: service_request,
          stored_file: stored_file,
          uploaded_by: actor
        )
        event = publish!(attachment, "service_request.attached",
          payload: { service_request_id: service_request.id, stored_file_id: stored_file.id, byte_size: bytes.bytesize })
        Result.new(record: attachment, events: [ event ])
      end
    end
  end
end
