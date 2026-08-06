Rails.application.config.after_initialize do
  Security::SecretRegistry.validate_production!
end
