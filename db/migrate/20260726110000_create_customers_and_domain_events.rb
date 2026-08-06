class CreateCustomersAndDomainEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.string :email_address
      t.string :status, null: false, default: "active"
      t.text :notes
      t.integer :lock_version, null: false, default: 0
      t.timestamps
    end

    add_index :customers, [ :organization_id, :name ]
    add_index :customers, [ :organization_id, :email_address ]

    create_table :domain_events do |t|
      t.references :organization, foreign_key: true
      t.references :actor, foreign_key: { to_table: :users }
      t.string :event_type, null: false
      t.string :aggregate_type, null: false
      t.bigint :aggregate_id, null: false
      t.jsonb :payload, null: false, default: {}
      t.string :request_id
      t.datetime :occurred_at, null: false
      t.timestamps
    end

    add_index :domain_events, [ :aggregate_type, :aggregate_id, :occurred_at ], name: "index_domain_events_on_aggregate_and_time"
    add_index :domain_events, [ :organization_id, :occurred_at ]
  end
end
