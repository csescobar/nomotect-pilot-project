# frozen_string_literal: true

module VisualValidation
  class EnvironmentPreparer
    class ActiveRecordDatabaseConfiguration
      def to_h
        ActiveRecord::Base.connection_db_config.configuration_hash
      end
    end

    CUSTOMERS = [
      [ "Aster Labs", "active" ],
      [ "Beacon Operations", "active" ],
      [ "Cedar Analytics", "inactive" ],
      [ "Delta Manufacturing", "active" ],
      [ "Evergreen Health", "active" ],
      [ "Fieldstone Logistics", "inactive" ],
      [ "Granite Services", "active" ],
      [ "Harbor Retail", "active" ],
      [ "Ion Consulting", "inactive" ],
      [ "Juniper Systems", "active" ],
      [ "Keystone Foods", "active" ],
      [ "Lumen Energy", "inactive" ]
    ].freeze

    def initialize(owner_creator: nil, environment: Rails.env.to_s)
      @owner_creator = owner_creator || Installation::PlatformOwnerCreator.new(
        configuration: ActiveRecordDatabaseConfiguration.new
      )
      @environment = environment.to_s
    end

    def prepare!
      validate_environment!
      owner = create_owner!
      organization = Organization.find(owner.organization_id)

      ApplicationRecord.transaction do
        organization.update!(theme: "light")
        create_customers!(organization)
      end

      write_ephemeral_installation_state!
      organization
    end

    private

    attr_reader :owner_creator, :environment

    def validate_environment!
      enabled = ActiveModel::Type::Boolean.new.cast(ENV.fetch("VISUAL_VALIDATION_ENABLED", "false"))
      raise "Visual-validation preparation is disabled" unless enabled
      raise "Visual-validation preparation requires the production runtime" unless environment == "production"
    end

    def create_owner!
      password = ENV.fetch("VISUAL_VALIDATION_PASSWORD")
      owner_creator.create!(
        email_address: ENV.fetch("VISUAL_VALIDATION_EMAIL"),
        organization_name: ENV.fetch("VISUAL_VALIDATION_ORGANIZATION", "NomoTect Visual Validation"),
        password:,
        password_confirmation: password
      )
    end

    def create_customers!(organization)
      CUSTOMERS.each_with_index do |(name, status), index|
        customer = organization.customers.find_or_initialize_by(name:)
        customer.assign_attributes(
          email_address: "customer-#{index + 1}@example.com",
          status:,
          notes: index.even? ? "Representative visual-validation record" : nil
        )
        customer.save!
      end
    end

    def write_ephemeral_installation_state!
      Installation::AppearanceStore.new.write!(
        application_name: "NomoTect Visual Validation",
        default_locale: "en",
        supported_locales: %w[en pt-BR],
        trademark_mode: "name_only"
      )
      Installation::StateStore.new.write!(
        state: "completed",
        metadata: {
          "profile" => "visual_validation",
          "ephemeral" => true
        }
      )
    end
  end
end
