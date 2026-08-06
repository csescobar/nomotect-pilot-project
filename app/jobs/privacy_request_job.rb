class PrivacyRequestJob < ApplicationJob
  queue_as :default

  def perform(organization_id, request_id)
    organization = Organization.find(organization_id)
    data_request = PrivacyRequest.find_by!(id: request_id, organization_id: organization.id)
    data_request.update!(status: "processing")

    processor = data_request.kind == "export" ? Privacy::DataExporter : Privacy::Anonymizer
    processor.call(request: data_request)
  end
end
