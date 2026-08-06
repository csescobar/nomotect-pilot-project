class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  rate_limit to: 10, within: 5.minutes, only: :create, with: -> { redirect_to new_session_url, alert: I18n.t("authentication.try_later") }

  def new
  end

  def create
    if user = User.authenticate_by(params.permit(:email_address, :password))
      start_new_session_for(user)
      Rails.logger.info(event: "authentication.succeeded", user_id: user.id, request_id: request.request_id)
      redirect_to after_authentication_url, status: :see_other
    else
      Rails.logger.warn(event: "authentication.failed", request_id: request.request_id)
      redirect_to new_session_path, status: :see_other, alert: I18n.t("authentication.invalid_credentials")
    end
  end

  def destroy
    user_id = Current.user&.id
    terminate_session
    Rails.logger.info(event: "authentication.signed_out", user_id:, request_id: request.request_id)
    redirect_to new_session_path, status: :see_other
  end
end
