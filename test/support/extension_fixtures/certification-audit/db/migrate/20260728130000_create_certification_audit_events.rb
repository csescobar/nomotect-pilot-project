# frozen_string_literal: true

class CreateCertificationAuditEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :certification_audit_events do |table|
      table.string :event_type, null: false
      table.jsonb :payload, null: false, default: {}
      table.timestamps
    end
  end
end
