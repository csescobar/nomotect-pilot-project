require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true
  config.action_controller.perform_caching = false
  config.active_storage.service = :local
  config.action_mailer.raise_delivery_errors = false
  config.action_mailer.perform_caching = false
  config.active_support.deprecation = :log
  if ENV["INSTALLATION_ENABLED"] == "true"
    config.active_record.migration_error = false
  else
    config.active_record.migration_error = :page_load
  end
  config.active_record.verbose_query_logs = true
  config.assets.quiet = true
  config.action_controller.raise_on_missing_callback_actions = true
end
