class ServiceRequestsController < ApplicationController
  before_action :set_organization
  before_action :set_service_request, only: %i[show edit update transition assign attach]

  def index
    authorize!(@organization, :show?)
    @grid_key = "service_requests"
  end

  def show
    authorize!(@service_request, :show?)
    @events = DomainEvent.where(aggregate_type: "ServiceRequest", aggregate_id: @service_request.id).recent_first.limit(20)
  end

  def new
    @service_request = ServiceRequest.new(organization: @organization, requester: Current.user)
    authorize!(@service_request, :create?)
  end

  def create
    @service_request = ServiceRequest.new(organization: @organization, requester: Current.user)
    authorize!(@service_request, :create?)

    result = ServiceRequests::Create.new.call(
      organization: @organization,
      attributes: service_request_params,
      requester: Current.user
    )
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("service_requests.created")
  rescue ActiveRecord::RecordInvalid => error
    @service_request = error.record
    render :new, status: :unprocessable_content
  end

  def edit
    authorize!(@service_request, :update?)
  end

  def update
    authorize!(@service_request, :update?)
    result = ServiceRequests::Update.new.call(service_request: @service_request, attributes: service_request_params)
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("service_requests.updated")
  rescue ActiveRecord::RecordInvalid => error
    @service_request = error.record
    render :edit, status: :unprocessable_content
  rescue ActiveRecord::StaleObjectError
    @service_request.reload
    flash.now[:alert] = t("service_requests.conflict")
    render :edit, status: :conflict
  end

  def transition
    authorize!(@service_request, :transition?)
    result = ServiceRequests::TransitionStatus.new.call(service_request: @service_request, new_status: params[:status])
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("service_requests.status_changed")
  rescue ArgumentError
    flash[:alert] = t("service_requests.invalid_transition")
    redirect_to [ @organization, @service_request ], status: :see_other
  end

  def assign
    authorize!(@service_request, :assign?)
    agent = resolve_assigned_agent

    result = ServiceRequests::Update.new.call(service_request: @service_request, attributes: { assigned_support_agent_id: agent&.id })
    NotifyAssignedAgentJob.perform_later(@organization.id, @service_request.id, Current.user.id) if agent
    redirect_to [ @organization, result.record ], status: :see_other, notice: t("service_requests.assigned")
  rescue ActiveRecord::RecordInvalid
    flash[:alert] = t("service_requests.invalid_agent")
    redirect_to [ @organization, @service_request ], status: :see_other
  end

  def attach
    authorize!(@service_request, :attach_file?)
    file = params.require(:service_request).permit(:file).fetch(:file)
    result = ServiceRequests::AttachFile.new.call(
      service_request: @service_request,
      name: file.original_filename,
      content_type: file.content_type,
      bytes: file.read
    )
    redirect_to [ @organization, result.record.service_request ], status: :see_other, notice: t("service_requests.attached")
  rescue ActionController::ParameterMissing
    flash[:alert] = t("service_requests.attachment_required")
    redirect_to [ @organization, @service_request ], status: :see_other
  end

  private

  def set_organization
    @organization = Organization.find(params[:organization_id])
  end

  def set_service_request
    @service_request = ServiceRequest.where(organization_id: @organization.id).find(params[:id])
  end

  def resolve_assigned_agent
    agent_id = params.dig(:service_request, :assigned_support_agent_id).presence
    return unless agent_id

    agent = @organization.users.find_by(id: agent_id)
    raise ActiveRecord::RecordInvalid, ServiceRequest.new if agent.nil?

    agent
  end

  def service_request_params
    params.require(:service_request).permit(:title, :description, :category, :priority, :status)
  end
end
