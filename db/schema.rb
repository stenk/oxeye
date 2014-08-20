# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20140814124840) do

  create_table "entries", force: true do |t|
    t.integer  "feed_id",                      null: false
    t.string   "url",          default: "",    null: false
    t.string   "title",        default: "",    null: false
    t.text     "content",      default: "",    null: false
    t.string   "author",       default: "",    null: false
    t.boolean  "is_read",      default: false, null: false
    t.datetime "published_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_favorite",  default: false, null: false
  end

  add_index "entries", ["feed_id", "is_read"], name: "index_entries_on_feed_id_and_is_read"
  add_index "entries", ["feed_id"], name: "index_entries_on_feed_id"
  add_index "entries", ["is_favorite"], name: "index_entries_on_is_favorite"

  create_table "feeds", force: true do |t|
    t.string   "url",                                  null: false
    t.string   "title",                default: "",    null: false
    t.string   "site_url",             default: "",    null: false
    t.string   "error",                default: "",    null: false
    t.integer  "error_count",          default: 0,     null: false
    t.boolean  "is_initialized",       default: false, null: false
    t.integer  "unread_entries_count", default: 0,     null: false
    t.integer  "last_entry_id"
    t.integer  "position",             default: 0,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
