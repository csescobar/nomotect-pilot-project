class CreateInstallationRecords < ActiveRecord::Migration[8.1]
  def change
    create_table :installation_records do |table|
      table.string :environment, null: false
      table.integer :contract_version, null: false
      table.string :schema_version, null: false
      table.string :status, null: false
      table.jsonb :metadata, null: false, default: {}
      table.timestamps
    end

    add_index :installation_records, %i[environment created_at]
    add_check_constraint :installation_records,
      "status IN ('migrated', 'owner_created', 'completed')",
      name: "installation_records_status"
  end
end
