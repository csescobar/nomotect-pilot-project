class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |table|
      table.string :email_address, null: false
      table.string :password_digest, null: false
      table.string :locale, null: false, default: "en"
      table.timestamps
    end

    add_index :users, "lower(email_address)", unique: true, name: "index_users_on_lower_email_address"
  end
end
