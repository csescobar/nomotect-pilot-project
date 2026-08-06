class CreatePrivacyGovernance < ActiveRecord::Migration[8.1]
  def change
    create_table :privacy_requests do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :requested_by, null: false, foreign_key: { to_table: :users }
      t.string :kind, null: false
      t.string :status, null: false, default: "pending"
      t.jsonb :result, null: false, default: {}
      t.text :failure_reason
      t.datetime :completed_at
      t.timestamps
    end

    add_check_constraint :privacy_requests,
      "kind IN ('export', 'anonymize')",
      name: "privacy_requests_kind_check"
    add_check_constraint :privacy_requests,
      "status IN ('pending', 'processing', 'completed', 'failed')",
      name: "privacy_requests_status_check"

    create_table :privacy_preferences do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :purpose, null: false
      t.boolean :granted, null: false, default: false
      t.datetime :decided_at, null: false
      t.timestamps
    end
    add_index :privacy_preferences, %i[organization_id user_id purpose], unique: true, name: "index_privacy_preferences_unique"

    create_table :retention_policies do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :record_type, null: false
      t.integer :retention_days, null: false
      t.boolean :enabled, null: false, default: true
      t.timestamps
    end
    add_index :retention_policies, %i[organization_id record_type], unique: true
    add_check_constraint :retention_policies, "retention_days > 0", name: "retention_policies_positive_days"
  end
end
