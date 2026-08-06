require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = ENV["CI"].present?
  config.public_file_server.headers = { "cache-control" => "public, max-age=3600" }
  config.consider_all_requests_local = true
  config.cache_store = :null_store
  config.action_dispatch.show_exceptions = :rescuable
  config.active_storage.service = :test
  config.action_mailer.delivery_method = :test
  config.action_mailer.default_url_options = { host: "example.test" }
  config.active_support.deprecation = :stderr
  config.active_record.maintain_test_schema = true
  config.action_controller.raise_on_missing_callback_actions = true
end
