class CreatePlatformRoles < ActiveRecord::Migration[8.1]
  def change
    create_table :platform_roles do |table|
      table.references :user, null: false, foreign_key: true, index: { unique: true }
      table.string :role, null: false
      table.timestamps
    end

    add_check_constraint :platform_roles,
      "role IN ('platform_admin')",
      name: "platform_roles_role"
  end
end
