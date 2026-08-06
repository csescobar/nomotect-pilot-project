class PrivacyRequestsController < ApplicationController
  before_action :enforce_privacy_throttle, only: :create

  def index
    Current.require_tenant!
    requests = PrivacyRequest.where(organization: Current.organization, requested_by: Current.user).order(created_at: :desc)
    render json: requests.as_json(only: %i[id kind status result failure_reason completed_at created_at])
  end

  def create
    Current.require_tenant!
    data_request = PrivacyRequest.create!(
      organization: Current.organization,
      requested_by: Current.user,
      kind: params.require(:kind)
    )
    PrivacyRequestJob.perform_later(Current.organization.id, data_request.id)
    render json: data_request.as_json(only: %i[id kind status created_at]), status: :accepted
  end

  private

  def enforce_privacy_throttle
    Current.require_tenant!
    result = Security::Throttle.check!(
      scope: "privacy-request",
      identity: "#{Current.organization.id}:#{Current.user.id}",
      limit: 5,
      period: 1.hour
    )
    return if result.allowed

    response.set_header("Retry-After", result.retry_after.to_s)
    render json: { error: I18n.t("privacy_requests.rate_limited") }, status: :too_many_requests
  end
end
