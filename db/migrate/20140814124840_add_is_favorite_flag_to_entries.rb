class AddIsFavoriteFlagToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :is_favorite, :boolean, null: false, default: false
    add_index :entries, :is_favorite
  end
end
