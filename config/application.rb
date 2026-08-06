require_relative "boot"

require "rails/all"

Bundler.require(*Rails.groups)

module NomoTect
  class Application < Rails::Application
    config.load_defaults 8.1
    config.autoload_lib(ignore: %w[assets tasks])

    application_layer = root.join("application")
    %w[controllers helpers jobs models operations policies].each do |component|
      path = application_layer.join("app", component).to_s
      config.autoload_paths << path
      config.eager_load_paths << path
    end
    config.paths["app/views"] << application_layer.join("app/views").to_s
    config.paths["config/initializers"] << application_layer.join("config/initializers").to_s
    config.paths["config/routes"] << application_layer.join("config/routes").to_s
    config.paths["db/migrate"] << application_layer.join("db/migrate").to_s
    config.i18n.load_path += Dir[application_layer.join("config/locales/**/*.{rb,yml}")]

    config.time_zone = "UTC"
    config.active_record.default_timezone = :utc
    config.i18n.available_locales = [ :en, :"pt-BR" ]
    config.i18n.default_locale = :en
    config.i18n.fallbacks = true

    config.generators.system_tests = nil
    config.action_controller.include_all_helpers = false

    config.filter_parameters += %i[
      password password_confirmation token secret authorization cookie
    ]
  end
end
