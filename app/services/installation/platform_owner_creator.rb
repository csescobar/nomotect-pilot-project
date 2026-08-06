require "bcrypt"

module Installation
  class PlatformOwnerCreator
    Connection = Class.new(ActiveRecord::Base) do
      self.abstract_class = true
    end

    UserRecord = Class.new(Connection) do
      self.table_name = "users"
    end

    OrganizationRecord = Class.new(Connection) do
      self.table_name = "organizations"
    end

    MembershipRecord = Class.new(Connection) do
      self.table_name = "memberships"
    end

    PlatformRoleRecord = Class.new(Connection) do
      self.table_name = "platform_roles"
    end

    InstallationRecord = Class.new(Connection) do
      self.table_name = "installation_records"
    end

    def initialize(configuration: RuntimeDatabaseConfiguration.new, progress: ProgressStore.new)
      @configuration = configuration
      @progress = progress
    end

    def create!(attributes)
      input = validate!(attributes)
      progress.publish(event: :platform_owner, status: :started, message: "Creating initial platform administrator and organization")
      Connection.establish_connection(configuration.to_h)

      result = Connection.transaction do
        user = find_or_create_user!(input)
        platform_role = reconcile_platform_admin_role!(user)
        organization = find_or_create_organization!(input)
        membership = reconcile_owner_membership!(user, organization)
        complete_installation_record!(user, platform_role, organization, membership)
        Result.new(user.id, platform_role.id, organization.id, membership.id)
      end

      progress.publish(event: :platform_owner, status: :completed, message: "Initial platform administrator and organization created")
      result
    rescue StandardError
      progress.publish(event: :platform_owner, status: :failed, message: "Platform administrator creation failed")
      raise
    ensure
      Connection.remove_connection
    end

    Result = Data.define(:user_id, :platform_role_id, :organization_id, :membership_id)

    private

    attr_reader :configuration, :progress

    def validate!(attributes)
      input = attributes.to_h.symbolize_keys
      email = input[:email_address].to_s.strip.downcase
      name = input[:organization_name].to_s.strip
      password = input[:password].to_s
      confirmation = input[:password_confirmation].to_s

      raise ArgumentError, "A valid administrator email address is required" unless URI::MailTo::EMAIL_REGEXP.match?(email)
      raise ArgumentError, "Organization name is required" if name.blank?
      raise ArgumentError, "Password must contain at least 12 characters" if password.length < 12
      raise ArgumentError, "Password confirmation does not match" unless ActiveSupport::SecurityUtils.secure_compare(password, confirmation)

      { email_address: email, organization_name: name, password: password }
    end

    def find_or_create_user!(input)
      user = UserRecord.find_or_initialize_by(email_address: input.fetch(:email_address))
      user.password_digest = BCrypt::Password.create(input.fetch(:password))
      user.locale ||= AppearanceStore.new.read.fetch("default_locale", "en")
      user.time_zone ||= Localization::SupportedLocales.fetch(user.locale).time_zone
      user.save!
      user
    end

    def reconcile_platform_admin_role!(user)
      role = PlatformRoleRecord.find_or_initialize_by(user_id: user.id)
      role.role = "platform_admin"
      role.save!
      role
    end

    def find_or_create_organization!(input)
      slug = input.fetch(:organization_name).parameterize.presence || "organization"
      organization = OrganizationRecord.find_or_initialize_by(slug: slug)
      organization.name = input.fetch(:organization_name)
      organization.locale ||= AppearanceStore.new.read.fetch("default_locale", "en")
      organization.time_zone ||= Localization::SupportedLocales.fetch(organization.locale).time_zone
      organization.theme ||= "system"
      organization.save!
      organization
    end

    def reconcile_owner_membership!(user, organization)
      membership = MembershipRecord.find_or_initialize_by(user_id: user.id, organization_id: organization.id)
      membership.role = "owner"
      membership.save!
      membership
    end

    def complete_installation_record!(user, platform_role, organization, membership)
      record = InstallationRecord.where(environment: Rails.env).order(id: :desc).first || InstallationRecord.new(environment: Rails.env)
      record.contract_version = 1
      record.schema_version ||= current_schema_version
      record.status = "completed"
      record.metadata = {
        platform_admin_user_id: user.id,
        platform_role_id: platform_role.id,
        initial_organization_id: organization.id,
        initial_owner_membership_id: membership.id
      }
      record.save!
    end

    def current_schema_version
      schema_migration = ActiveRecord::SchemaMigration.new(Connection.connection_pool)
      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate"), schema_migration).current_version.to_s
    end
  end
end
