class OrganizationInvitationsController < ApplicationController
  before_action :set_organization, only: %i[create destroy]

  def create
    authorize!(@organization, :manage_members?)
    @invitation = @organization.organization_invitations.new(
      email_address: invitation_params[:email_address],
      role: requested_role,
      invited_by: Current.user
    )

    if @invitation.save
      redirect_to @organization, status: :see_other, notice: t("organization_invitations.created")
    else
      load_organization_members
      render "organizations/show", status: :unprocessable_content
    end
  end

  def destroy
    authorize!(@organization, :manage_members?)
    invitation = @organization.organization_invitations.pending.find(params[:id])
    invitation.revoke!
    redirect_to @organization, status: :see_other, notice: t("organization_invitations.revoked")
  end

  def accept
    invitation = OrganizationInvitation.find_by_acceptance_token!(params[:token])
    invitation.accept!(Current.user)
    redirect_to invitation.organization, status: :see_other, notice: t("organization_invitations.accepted")
  rescue ActiveSupport::MessageVerifier::InvalidSignature, ActiveRecord::RecordNotFound
    redirect_to organizations_path, status: :see_other, alert: t("organization_invitations.invalid")
  rescue ActiveRecord::RecordInvalid
    redirect_to organizations_path, status: :see_other, alert: t("organization_invitations.email_mismatch")
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def invitation_params
    params.require(:organization_invitation).permit(:email_address)
  end

  def requested_role
    role = params.require(:organization_invitation).fetch(:role)
    return role if Membership.manageable_roles.include?(role)

    raise ActionController::BadRequest, "Unsupported invitation role"
  end

  def load_organization_members
    @membership = @organization.membership_for(Current.user)
    @memberships = @organization.memberships.includes(:user).order(:created_at)
    @pending_invitations = @organization.organization_invitations.pending.order(:created_at)
  end
end
