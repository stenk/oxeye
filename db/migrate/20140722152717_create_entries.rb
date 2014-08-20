class CreateEntries < ActiveRecord::Migration
  def change
    create_table :entries do |t|
      t.references :feed, null: false
      t.string :url, null: false, default: ''
      t.string :title, null: false, default: ''
      t.text :content, null: false, default: ''
      t.string :author, null: false, default: ''
      t.boolean :is_read, null: false, default: false

      t.datetime :published_at
      t.timestamps
    end

    add_index :entries, [:feed_id, :is_read]

    # for retrieving of feed's entries in order of their creation:
    add_index :entries, :feed_id
  end
end
