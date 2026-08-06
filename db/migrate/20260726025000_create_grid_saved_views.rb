class CreateGridSavedViews < ActiveRecord::Migration[8.0]
  def change
    create_table :grid_saved_views do |t|
      t.references :user, null: false, foreign_key: true
      t.string :grid_key, null: false
      t.string :name, null: false
      t.jsonb :query, null: false, default: {}
      t.jsonb :preferences, null: false, default: {}
      t.boolean :default, null: false, default: false
      t.timestamps
    end

    add_index :grid_saved_views, [ :user_id, :grid_key, :name ], unique: true
    add_index :grid_saved_views, [ :user_id, :grid_key ], unique: true, where: '"default" = TRUE', name: "index_grid_saved_views_on_user_grid_default"
  end
end
