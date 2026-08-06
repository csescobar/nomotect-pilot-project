Rails.application.config.to_prepare do
  ApplicationRoles.reset!
  GridEngine::Catalog.reset!
  loaded_files = []

  %w[roles grids].each do |name|
    path = Rails.root.join("application/config/#{name}.rb")
    next unless path.file?

    load path
    loaded_files << path.relative_path_from(Rails.root).to_s
  end

  ApplicationRoles.seal!
  GridEngine::Catalog.seal!
  Rails.application.config.x.application_registration_files = loaded_files.freeze
end
