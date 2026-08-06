class AddLocalizationPreferencesToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :locale, :string, default: "en", null: false unless column_exists?(:users, :locale)
    add_column :users, :time_zone, :string, default: "UTC", null: false unless column_exists?(:users, :time_zone)
  end
end
