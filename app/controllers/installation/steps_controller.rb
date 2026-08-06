module Installation
  class StepsController < BaseController
    def show
      @state = StateStore.new.read.fetch("state")
      @step = Wizard.new.step(normalized_step)
      load_step
    end

    def update
      @state = StateStore.new.read.fetch("state")
      @step = Wizard.new.step(normalized_step)
      return update_appearance if @step.name == "appearance"
      return test_database if @step.name == "database" && params[:commit] == "Test connection"
      return provision_database if @step.name == "database"
      return run_migrations if @step.name == "provisioning"
      return complete_installation if @step.name == "platform_owner"

      head :method_not_allowed
    rescue ArgumentError, DatabaseConnector::ConnectionError, ExecutionLock::AlreadyLocked,
      MigrationRunner::VerificationError => error
      load_step
      flash.now[:alert] = error.message
      render :show, status: :unprocessable_entity
    end

    def export
      head :forbidden unless Configuration.token_editing_allowed?
      send_file Rails.root.join("config/design_tokens/tokens.yml"), type: "application/yaml", disposition: "attachment"
    end

    private

    def update_appearance
      AppearanceUpdater.new.update!(appearance_attributes, uploads: appearance_uploads, token_yaml: params[:token_yaml])
      advance_to_database!
      redirect_to installation_step_path("database"), status: :see_other, notice: "Appearance saved."
    end

    def test_database
      configuration = database_configuration
      DatabaseConnector.new.test!(configuration)
      persist_database_metadata!(configuration)
      @database = configuration.public_attributes.merge("admin_password" => params.dig(:database, :admin_password)).stringify_keys
      flash.now[:notice] = "PostgreSQL connection succeeded."
      render :show
    end

    def provision_database
      configuration = database_configuration
      ExecutionLock.new.synchronize { DatabaseProvisioner.new.provision!(configuration) }
      persist_database_metadata!(configuration)
      advance_to_provisioning!
      redirect_to installation_step_path("provisioning"), status: :see_other, notice: "Database provisioned."
    end

    def run_migrations
      transition_to!("migrations", "migrations_started" => true)
      result = ExecutionLock.new.synchronize { MigrationRunner.new.run! }
      transition_to!("platform_owner", "schema_version" => result.schema_version, "migrations_completed" => true)
      redirect_to installation_step_path("platform-owner"), status: :see_other, notice: "Database migrations completed."
    rescue StandardError
      restore_provisioning_state!
      raise
    end

    def complete_installation
      ExecutionLock.new.synchronize { PlatformOwnerCreator.new.create!(platform_owner_attributes) }
      transition_to!("completed", "platform_owner_created" => true, "completed_at" => Time.current.utc.iso8601)
      session.delete(:installation_authorized)
      redirect_to root_path, status: :see_other, notice: "Installation completed. Sign in with the platform owner account."
    end

    def load_step
      load_appearance if @step.name == "appearance"
      load_database if @step.name == "database"
      @progress = ProgressStore.new.read if %w[database provisioning migrations platform_owner].include?(@step.name)
    end

    def load_appearance
      @appearance = AppearanceStore.new.read
      @token_yaml = Rails.root.join("config/design_tokens/tokens.yml").read
    end

    def load_database
      metadata = StateStore.new.read.fetch("metadata", {}).fetch("database", {})
      @database = {
        "host" => metadata.fetch("host", "localhost"),
        "port" => metadata.fetch("port", 5432),
        "maintenance_database" => metadata.fetch("maintenance_database", "postgres"),
        "application_database" => metadata.fetch("application_database", "nomotect"),
        "application_username" => metadata.fetch("application_username", "nomotect"),
        "sslmode" => metadata.fetch("sslmode", "prefer")
      }
    end

    def database_configuration
      DatabaseConfiguration.new(params.require(:database).permit(*DatabaseConfiguration::ATTRIBUTES))
    end

    def platform_owner_attributes
      params.require(:platform_owner).permit(:email_address, :organization_name, :password, :password_confirmation)
    end

    def persist_database_metadata!(configuration)
      store = StateStore.new
      current = store.read
      metadata = current.fetch("metadata", {}).merge("database" => configuration.public_attributes)
      store.write!(state: current.fetch("state"), metadata: metadata)
    end

    def appearance_attributes
      params.require(:appearance).permit(:application_name, :default_locale, :trademark_mode, :logo, :compact_logo, :favicon, supported_locales: [])
    end

    def appearance_uploads
      {
        logo: params.dig(:appearance, :logo),
        compact_logo: params.dig(:appearance, :compact_logo),
        favicon: params.dig(:appearance, :favicon)
      }
    end

    def advance_to_database!
      store = StateStore.new
      current = store.read
      state = current.fetch("state")
      if state == "database"
        store.write!(state: "database", metadata: current.fetch("metadata", {}).merge("appearance_saved" => true))
        return
      end

      state = StateMachine.new(state).transition_to("appearance").state if state == "not_started"
      next_state = StateMachine.new(state).transition_to("database").state
      store.write!(state: next_state, metadata: current.fetch("metadata", {}).merge("appearance_saved" => true))
    end

    def advance_to_provisioning!
      transition_to!("provisioning", "database_provisioned" => true)
    end

    def transition_to!(target, metadata)
      store = StateStore.new
      current = store.read
      state = current.fetch("state")
      next_state = state == target ? target : StateMachine.new(state).transition_to(target).state
      store.write!(state: next_state, metadata: current.fetch("metadata", {}).merge(metadata))
    end

    def restore_provisioning_state!
      store = StateStore.new
      current = store.read
      store.write!(state: "provisioning", metadata: current.fetch("metadata", {}).merge("migrations_failed" => true))
    end

    def normalized_step
      requested = params[:step].to_s.tr("-", "_")
      return "appearance" if @state == "not_started" || @state == "failed"

      requested.presence || @state
    end
  end
end
