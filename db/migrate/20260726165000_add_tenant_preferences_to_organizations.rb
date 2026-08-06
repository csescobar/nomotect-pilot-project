class AddTenantPreferencesToOrganizations < ActiveRecord::Migration[8.1]
  def change
    add_column :organizations, :locale, :string, null: false, default: "en"
    add_column :organizations, :time_zone, :string, null: false, default: "UTC"
    add_column :organizations, :theme, :string, null: false, default: "system"

    add_check_constraint :organizations,
      "theme IN ('light', 'dark', 'system')",
      name: "organizations_theme_check"
  end
end
