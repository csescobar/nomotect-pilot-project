class CreateServiceRequestAttachments < ActiveRecord::Migration[8.1]
  def change
    create_table :service_request_attachments do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :service_request, null: false, foreign_key: true
      t.references :stored_file, null: false, foreign_key: true
      t.references :uploaded_by, null: false, foreign_key: { to_table: :users }

      t.timestamps
    end

    add_index :service_request_attachments, [ :service_request_id, :stored_file_id ], unique: true, name: "index_sr_attachments_on_request_and_file"
  end
end
