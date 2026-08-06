class OrganizationsController < ApplicationController
  before_action :set_organization, only: %i[show edit update destroy]

  def index
    @organizations = Current.user.organizations.order(:name)
  end

  def show
    authorize!(@organization, :show?)
    @membership = @organization.membership_for(Current.user)
    @memberships = @organization.memberships.includes(:user).order(:created_at)
    @pending_invitations = @organization.organization_invitations.pending.order(:created_at)
    @invitation = @organization.organization_invitations.new
  end

  def new
    @organization = Organization.new
    authorize!(@organization, :create?)
  end

  def create
    @organization = Organization.new(organization_params)
    authorize!(@organization, :create?)

    Organization.transaction do
      @organization.save!
      @organization.memberships.create!(user: Current.user, role: "owner")
    end

    redirect_to @organization, status: :see_other, notice: t("organizations.created")
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_content
  end

  def edit
    authorize!(@organization, :update?)
  end

  def update
    authorize!(@organization, :update?)

    if @organization.update(organization_params)
      redirect_to @organization, status: :see_other, notice: t("organizations.updated")
    else
      render :edit, status: :unprocessable_content
    end
  end

  def destroy
    authorize!(@organization, :destroy?)
    @organization.destroy!
    redirect_to organizations_path, status: :see_other, notice: t("organizations.destroyed")
  end

  private

  def set_organization
    @organization = Organization.find(params[:id])
  end

  def organization_params
    params.require(:organization).permit(:name)
  end
end
