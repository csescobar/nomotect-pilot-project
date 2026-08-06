# frozen_string_literal: true

module NomoTect
  module SampleAudit
    Provider = ->(event) do
      {
        event_id: event.fetch(:id),
        recorded: true
      }.freeze
    end
  end
end

Extensions.register("nomotect.sample-audit") do |extension|
  extension.capability(
    "sample.audit-events",
    version: 1,
    provider: NomoTect::SampleAudit::Provider
  )
  extension.documentation ->(index) { index }
end
