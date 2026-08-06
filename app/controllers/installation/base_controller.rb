module Installation
  class BaseController < ApplicationController
    layout "installation"
    allow_unauthenticated_access
    skip_before_action :enforce_extension_readiness

    before_action :ensure_enabled
    before_action :ensure_incomplete
    before_action :authorize_bootstrap

    private

    def ensure_enabled
      head :not_found unless Configuration.enabled?
    end

    def ensure_incomplete
      redirect_to root_path if StateStore.new.completed?
    end

    def authorize_bootstrap
      return unless Configuration.production_token_required?
      return if session[:installation_authorized]

      token = BootstrapToken.new
      if token.valid?(params[:token])
        session[:installation_authorized] = true
      else
        head :forbidden
      end
    end
  end
end
