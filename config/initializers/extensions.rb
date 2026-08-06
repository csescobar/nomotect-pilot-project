Rails.application.config.after_initialize do
  Extensions::Runtime.boot!
end
