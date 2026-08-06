Rails.application.config.after_initialize do
  next unless Rails.env.production? || ENV["STRUCTURED_LOGS"] == "true"

  logger = ActiveSupport::Logger.new($stdout)
  logger.formatter = Platform::JsonLogFormatter.new
  Rails.logger = ActiveSupport::TaggedLogging.new(logger)
end

Rails.application.config.middleware.use Rack::Attack
