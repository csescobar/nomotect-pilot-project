class CreateServiceRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :service_requests do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :requester, null: false, foreign_key: { to_table: :users }
      t.references :assigned_support_agent, null: true, foreign_key: { to_table: :users }

      t.string :identifier, null: false
      t.string :title, null: false
      t.text :description, null: false, default: ""
      t.string :category, null: false
      t.string :priority, null: false
      t.string :status, null: false, default: "open"
      t.datetime :resolved_at
      t.datetime :closed_at

      t.timestamps
    end

    add_index :service_requests, [ :organization_id, :identifier ], unique: true
    add_index :service_requests, [ :organization_id, :status ]
    add_index :service_requests, [ :organization_id, :priority ]
    add_index :service_requests, [ :organization_id, :requester_id ]
  end
end
