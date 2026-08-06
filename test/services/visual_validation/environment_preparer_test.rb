# frozen_string_literal: true

require "test_helper"

module VisualValidation
  class EnvironmentPreparerTest < ActiveSupport::TestCase
    ENV_KEYS = %w[
      INSTALLATION_APPEARANCE_PATH
      INSTALLATION_STATE_PATH
      VISUAL_VALIDATION_EMAIL
      VISUAL_VALIDATION_ENABLED
      VISUAL_VALIDATION_ORGANIZATION
      VISUAL_VALIDATION_PASSWORD
    ].freeze

    setup do
      @previous_environment = ENV_KEYS.to_h { |key| [ key, ENV[key] ] }
      ENV["VISUAL_VALIDATION_ENABLED"] = "true"
      ENV["VISUAL_VALIDATION_EMAIL"] = "reviewer@example.com"
      ENV["VISUAL_VALIDATION_PASSWORD"] = "validation-secret-from-operator"
      ENV["VISUAL_VALIDATION_ORGANIZATION"] = "Visual Validation Test"
      ENV["INSTALLATION_STATE_PATH"] = Rails.root.join("tmp/visual-validation-state-#{Process.pid}.json").to_s
      ENV["INSTALLATION_APPEARANCE_PATH"] = Rails.root.join("tmp/visual-validation-appearance-#{Process.pid}.json").to_s
      paths.each { |path| FileUtils.rm_f(path) }
    end

    teardown do
      paths.each { |path| FileUtils.rm_f(path) }
      @previous_environment.each do |key, value|
        value.nil? ? ENV.delete(key) : ENV[key] = value
      end
    end

    test "prepares deterministic records and ephemeral installation state idempotently" do
      organization = Organization.create!(
        name: "Visual Validation Test",
        locale: "en",
        time_zone: "UTC",
        theme: "dark"
      )
      owner_result = Data.define(:organization_id).new(organization.id)
      owner_creator = Object.new
      owner_creator.define_singleton_method(:create!) { |_attributes| owner_result }
      preparer = EnvironmentPreparer.new(owner_creator:, environment: "production")

      2.times { preparer.prepare! }

      assert_equal "light", organization.reload.theme
      assert_equal EnvironmentPreparer::CUSTOMERS.size, organization.customers.count
      assert_equal "completed", Installation::StateStore.new.read.fetch("state")
      assert_equal "NomoTect Visual Validation", Installation::AppearanceStore.new.read.fetch("application_name")
    end

    test "fails closed outside the explicit validation profile" do
      ENV["VISUAL_VALIDATION_ENABLED"] = "false"

      error = assert_raises(RuntimeError) do
        EnvironmentPreparer.new(environment: "production").prepare!
      end

      assert_equal "Visual-validation preparation is disabled", error.message
    end

    test "uses the database connection already configured by Rails" do
      configuration = EnvironmentPreparer::ActiveRecordDatabaseConfiguration.new.to_h

      assert_equal ActiveRecord::Base.connection_db_config.configuration_hash, configuration
      assert configuration[:database].present?
    end

    private

    def paths
      %w[INSTALLATION_STATE_PATH INSTALLATION_APPEARANCE_PATH].map { |name| Pathname(ENV.fetch(name)) }
    end
  end
end
