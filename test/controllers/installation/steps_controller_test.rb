require "test_helper"

class Installation::StepsControllerTest < ActionDispatch::IntegrationTest
  ENV_KEYS = %w[INSTALLATION_ENABLED INSTALLATION_STATE_PATH INSTALLATION_APPEARANCE_PATH].freeze

  setup do
    @previous_environment = ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
    ENV["INSTALLATION_ENABLED"] = "true"
    ENV["INSTALLATION_STATE_PATH"] = Rails.root.join("tmp/installation-state-#{Process.pid}.json").to_s
    ENV["INSTALLATION_APPEARANCE_PATH"] = Rails.root.join("tmp/installation-appearance-#{Process.pid}.json").to_s
    installation_paths.each { |path| FileUtils.rm_f(path) }
  end

  teardown do
    installation_paths.each { |path| FileUtils.rm_f(path) }
    @previous_environment.each do |key, value|
      value.nil? ? ENV.delete(key) : ENV[key] = value
    end
  end

  test "redirects normal requests to the active installation step" do
    get root_path
    assert_redirected_to "/installation/appearance"
  end

  test "renders the appearance form without authentication" do
    get installation_path
    assert_response :success
    assert_select ".wizard-card"
    assert_select "form"
    assert_select "textarea[name='token_yaml']"
  end

  test "saves appearance and advances to database" do
    patch installation_step_path("appearance"), params: {
      authenticity_token: form_authenticity_token,
      appearance: {
        application_name: "Acme Platform",
        default_locale: "en",
        supported_locales: %w[en pt-BR]
      }
    }

    assert_redirected_to installation_step_path("database")
    assert_equal "database", Installation::StateStore.new.read.fetch("state")
    assert_equal "Acme Platform", Installation::AppearanceStore.new.read.fetch("application_name")
  end

  test "handles re-saving appearance when state is already database" do
    Installation::StateStore.new.write!(state: "database")

    patch installation_step_path("appearance"), params: {
      authenticity_token: form_authenticity_token,
      appearance: {
        application_name: "Acme Platform Updated",
        default_locale: "en",
        supported_locales: %w[en pt-BR]
      }
    }

    assert_redirected_to installation_step_path("database")
    assert_equal "database", Installation::StateStore.new.read.fetch("state")
    assert_equal "Acme Platform Updated", Installation::AppearanceStore.new.read.fetch("application_name")
  end

  test "renders database fields without persisted administrative credentials" do
    Installation::StateStore.new.write!(
      state: "database",
      metadata: {
        "database" => {
          "host" => "db.internal",
          "port" => 5433,
          "maintenance_database" => "postgres",
          "application_database" => "acme_platform",
          "application_username" => "acme_runtime",
          "sslmode" => "require"
        }
      }
    )

    get installation_step_path("database")

    assert_response :success
    assert_select "input[name='database[host]'][value='db.internal']"
    password_input = css_select("input[name='database[admin_password]']").first
    assert password_input
    assert password_input["value"].blank?
    assert_select "input[name='database[application_database]'][value='acme_platform']"
  end

  test "renders platform owner fields without persisted passwords" do
    Installation::StateStore.new.write!(state: "platform_owner")

    get installation_step_path("platform-owner")

    assert_response :success
    assert_select "input[name='platform_owner[organization_name]']"
    assert_select "input[name='platform_owner[email_address]']"
    assert_select "input[name='platform_owner[password]']:not([value])"
    assert_select "input[name='platform_owner[password_confirmation]']:not([value])"
  end

  test "rejects an unsupported default locale" do
    patch installation_step_path("appearance"), params: {
      authenticity_token: form_authenticity_token,
      appearance: {
        application_name: "Acme Platform",
        default_locale: "pt-BR",
        supported_locales: [ "en" ]
      }
    }

    assert_response :unprocessable_entity
    assert_equal "not_started", Installation::StateStore.new.read.fetch("state")
  end

  test "preserves health endpoints while installation is incomplete" do
    get health_path
    assert_response :success
  end

  test "completed state bypasses the installation gate" do
    Installation::StateStore.new.write!(state: "completed")
    get root_path
    assert_response :redirect
    assert_not_equal "/installation/appearance", response.location
  end

  private

  def form_authenticity_token
    get installation_path
    css_select("input[name='authenticity_token']").first["value"]
  end

  def installation_paths
    [ Pathname(ENV.fetch("INSTALLATION_STATE_PATH")), Pathname(ENV.fetch("INSTALLATION_APPEARANCE_PATH")) ]
  end
end
