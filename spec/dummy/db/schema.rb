# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2022_07_06_110236) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "hyperstack_connections", force: :cascade do |t|
    t.string "channel"
    t.string "session"
    t.datetime "created_at"
    t.datetime "expires_at"
    t.datetime "refresh_at"
    t.index ["expires_at"], name: "index_hyperstack_connections_on_expires_at"
  end

  create_table "hyperstack_queued_messages", force: :cascade do |t|
    t.integer "connection_id"
    t.text "data"
    t.index ["connection_id"], name: "index_hyperstack_queued_messages_on_connection_id"
  end

  create_table "samples", force: :cascade do |t|
    t.text "description"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

end
