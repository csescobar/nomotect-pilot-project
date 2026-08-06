class MembershipsController < ApplicationController
  before_action :set_organization
  before_action :set_membership

  def update
    authorize!(@organization, :manage_members?)
    authorize_owner_change!

    if @membership.update(role: params.require(:membership).fetch(:role))
      redirect_to @organization, status: :see_other, notice: t("memberships.updated")
    else
      redirect_to @organization, status: :see_other, alert: @membership.errors.full_messages.to_sentence
    end
  end

  def destroy
    authorize!(@organization, :manage_members?)
    authorize_owner_change!

    if @membership.destroy
      redirect_to @organization, status: :see_other, notice: t("memberships.destroyed")
    else
      redirect_to @organization, status: :see_other, alert: @membership.errors.full_messages.to_sentence
    end
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_membership
    @membership = @organization.memberships.find(params[:id])
  end

  def authorize_owner_change!
    requested_role = params.dig(:membership, :role)
    return unless @membership.owner? || requested_role == "owner"

    authorize!(@organization, :manage_owners?)
  end
end
