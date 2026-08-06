class CreateEnterpriseServices < ActiveRecord::Migration[8.1]
  def change
    create_table :idempotency_records do |t|
      t.string :key, null: false
      t.string :scope, null: false, default: "default"
      t.string :status, null: false, default: "started"
      t.jsonb :result, null: false, default: {}
      t.datetime :expires_at
      t.timestamps
    end
    add_index :idempotency_records, %i[scope key], unique: true

    create_table :notifications do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :recipient, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :payload, null: false, default: {}
      t.datetime :delivered_at
      t.timestamps
    end

    create_table :stored_files do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :uploaded_by, foreign_key: { to_table: :users }
      t.string :name, null: false
      t.string :content_type, null: false
      t.bigint :byte_size, null: false
      t.string :checksum, null: false
      t.string :storage_key, null: false
      t.timestamps
    end
    add_index :stored_files, :storage_key, unique: true

    create_table :import_runs do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :requested_by, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.integer :processed_rows, null: false, default: 0
      t.integer :failed_rows, null: false, default: 0
      t.jsonb :error_details, null: false, default: []
      t.timestamps
    end

    create_table :webhook_endpoints do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :url, null: false
      t.string :secret, null: false
      t.boolean :enabled, null: false, default: true
      t.jsonb :events, null: false, default: []
      t.timestamps
    end

    create_table :feature_flags do |t|
      t.references :organization, foreign_key: true
      t.string :key, null: false
      t.boolean :enabled, null: false, default: false
      t.jsonb :metadata, null: false, default: {}
      t.timestamps
    end
    add_index :feature_flags, %i[organization_id key], unique: true
  end
end
