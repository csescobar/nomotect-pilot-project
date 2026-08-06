class HealthController < ActionController::Base
  def show
    ActiveRecord::Base.connection.select_value("SELECT 1")
    extension_readiness = Extensions::Runtime.readiness
    unless extension_readiness.fetch(:ready)
      return render json: {
        status: "unavailable",
        service: "nomotect-platform",
        extensions: extension_readiness
      }, status: :service_unavailable
    end

    render json: {
      status: "ok",
      service: "nomotect-platform",
      version: ENV.fetch("APP_VERSION", Platform::Version.current.to_s),
      extensions: extension_readiness,
      timestamp: Time.current.utc.iso8601
    }
  rescue StandardError => error
    Rails.logger.error(
      event: "health_check.failed",
      error_class: error.class.name,
      request_id: request.request_id
    )

    render json: { status: "unavailable", request_id: request.request_id },
      status: :service_unavailable
  end
end
