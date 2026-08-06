# frozen_string_literal: true

Extensions.register("certification.audit") do |extension|
  extension.capability(
    "certification.audit-events",
    version: 1,
    provider: ->(event) { event.fetch(:id) }
  )
  extension.configuration ->(settings) { settings }
  extension.migrations ->(context) { context }
  extension.routes ->(router) { router }
  extension.assets ->(paths) { paths }
  extension.documentation ->(index) { index }
end
