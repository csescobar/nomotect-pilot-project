class TenantSelectionsController < ApplicationController
  def update
    membership = Current.user.memberships.find_by!(organization_id: params.require(:organization_id))
    session[:active_organization_id] = membership.organization_id

    redirect_back fallback_location: organization_path(membership.organization), status: :see_other, notice: I18n.t("tenant_selection.updated")
  end
end
