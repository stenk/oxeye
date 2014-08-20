class CreateFeeds < ActiveRecord::Migration
  def change
    create_table :feeds do |t|
      t.string :url, null: false
      t.string :title, null: false, default: ''
      t.string :site_url, null: false, default: ''

      t.string  :error, null: false, default: ''
      t.integer :error_count, null: false, default: 0

      t.boolean :is_initialized, null: false, default: false
      t.integer :unread_entries_count, null: false, default: 0
      t.integer :last_entry_id

      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end
