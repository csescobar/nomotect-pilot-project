module ExtensionGate
  extend ActiveSupport::Concern

  included do
    prepend_before_action :enforce_extension_readiness
  end

  private

  def enforce_extension_readiness
    return if Installation::Configuration.enabled? && !Installation::StateStore.new.completed?

    Extensions::Runtime.boot! unless Extensions::Runtime.ready?
    return if Extensions::Runtime.traffic_allowed?

    head :service_unavailable
  end
end
