class CreateOrganizationInvitations < ActiveRecord::Migration[8.0]
  def change
    create_table :organization_invitations do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :invited_by, null: false, foreign_key: { to_table: :users }
      t.string :email_address, null: false
      t.string :role, null: false, default: "member"
      t.datetime :accepted_at
      t.datetime :revoked_at
      t.timestamps
    end

    add_index :organization_invitations,
      [ :organization_id, :email_address ],
      unique: true,
      where: "accepted_at IS NULL AND revoked_at IS NULL",
      name: "index_pending_organization_invitations"
  end
end
