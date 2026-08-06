Rails.application.config.filter_parameters += %i[
  password
  password_confirmation
  token
  installation_token
  admin_password
  database_password
  database_url
]
