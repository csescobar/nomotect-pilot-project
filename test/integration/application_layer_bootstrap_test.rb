require "test_helper"

class ApplicationLayerBootstrapTest < ActiveSupport::TestCase
  ROOT = Rails.root.join("application").freeze

  test "registers application-owned Ruby source paths for loading" do
    %w[controllers helpers jobs models operations policies].each do |component|
      path = ROOT.join("app", component).to_s

      assert_includes Rails.application.config.autoload_paths, path
      assert_includes Rails.application.config.eager_load_paths, path
    end
  end

  test "registers application-owned Rails integration paths" do
    assert_includes Rails.application.config.paths["app/views"].expanded, ROOT.join("app/views").to_s
    assert_includes Rails.application.config.paths["config/initializers"].expanded, ROOT.join("config/initializers/application.rb").to_s
    assert_includes Rails.application.config.paths["config/routes"].expanded, ROOT.join("config/routes/application.rb").to_s
    assert_includes Rails.application.config.paths["db/migrate"].expanded, ROOT.join("db/migrate").to_s
  end

  test "application route file is present in the reviewed draw path" do
    route_file = ROOT.join("config/routes/application.rb")

    assert route_file.file?
    assert_includes Rails.application.config.paths["config/routes"].expanded, route_file.to_s
  end
end
