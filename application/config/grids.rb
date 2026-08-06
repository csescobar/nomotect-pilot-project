GridEngine::Catalog.register("service_requests", definition: GridEngine::Definition.new(key: "service_requests", model_class: ServiceRequest) do
  column :identifier, type: :string
  column :title, type: :string
  column :category, type: :string
  column :priority, type: :string
  column :status, type: :string
  column :requester, attribute: :requester_id, type: :integer, filterable: false, visible: false
  column :created_at, type: :datetime
  sort :created_at, direction: :desc
end, scope: ->(user:, organization:, **) do
  return ServiceRequest.none unless organization

  ServiceRequests::VisibleTo.new(user: user, organization: organization).call
end)
