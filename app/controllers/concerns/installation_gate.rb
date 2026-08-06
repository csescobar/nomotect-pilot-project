module InstallationGate
  extend ActiveSupport::Concern

  ALLOWED_CONTROLLERS = %w[health rails/health].freeze

  included do
    prepend_before_action :enforce_installation
  end

  private

  def enforce_installation
    return unless Installation::Configuration.enabled?
    return if controller_path.start_with?("installation/")
    return if ALLOWED_CONTROLLERS.include?(controller_path)
    return if Installation::StateStore.new.completed?

    state = Installation::StateStore.new.read.fetch("state")
    redirect_to Installation::Wizard.new.path_for(state)
  end
end
