require_relative "../../app/services/installation/runtime_database_configuration"

runtime_env_path = Rails.root.join("var/installation/runtime.#{Rails.env}.env")

if runtime_env_path.exist?
  begin
    config = Installation::RuntimeDatabaseConfiguration.new(path: runtime_env_path).to_h
    ActiveRecord::Base.establish_connection(config)
  rescue StandardError => e
    Rails.logger.warn("Failed to load runtime database configuration: #{e.message}")
  end
end
