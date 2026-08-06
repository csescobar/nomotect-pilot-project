# frozen_string_literal: true

module NomoTect
  module ServiceDeskSla
    SLA_TARGETS = {
      "low" => 96.hours,
      "medium" => 48.hours,
      "high" => 24.hours,
      "critical" => 4.hours
    }.freeze

    Provider = lambda do |priority: nil|
      target = priority.nil? ? nil : SLA_TARGETS.fetch(priority.to_s, 24.hours)
      {
        priority: priority,
        target_seconds: target&.to_i,
        deterministic: true,
        version: 1
      }.freeze
    end
  end
end

Extensions.register("nomotect.service-desk-sla") do |extension|
  extension.capability(
    "service-desk.sla-target",
    version: 1,
    provider: NomoTect::ServiceDeskSla::Provider
  )
  extension.documentation ->(index) { index }
end
