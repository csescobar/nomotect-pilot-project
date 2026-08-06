require "test_helper"

module Installation
  class PlatformOwnerCreatorTest < ActiveSupport::TestCase
    test "reads the current schema version through the connection pool" do
      pool = Object.new
      schema_migration = Object.new
      migration_context = Struct.new(:current_version).new(20_260_801_120_000)
      observed_pool = nil
      observed_paths = nil
      observed_schema_migration = nil
      creator = PlatformOwnerCreator.new

      connection_class = PlatformOwnerCreator::Connection
      connection_class.stub(:connection_pool, pool) do
        ActiveRecord::SchemaMigration.stub(:new, ->(actual_pool) { observed_pool = actual_pool; schema_migration }) do
          ActiveRecord::MigrationContext.stub(:new, lambda { |paths, actual_schema_migration|
            observed_paths = paths
            observed_schema_migration = actual_schema_migration
            migration_context
          }) do
            assert_equal "20260801120000", creator.send(:current_schema_version)
          end
        end
      end

      assert_same pool, observed_pool
      assert_equal Rails.root.join("db/migrate"), observed_paths
      assert_same schema_migration, observed_schema_migration
    end
  end
end
