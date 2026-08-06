class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions do |table|
      table.references :user, null: false, foreign_key: true
      table.string :ip_address, limit: 45
      table.string :user_agent, limit: 512
      table.timestamps
    end
  end
end
