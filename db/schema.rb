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

ActiveRecord::Schema.define(version: 20151209170037) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "approvals", force: :cascade do |t|
    t.integer  "developer_id"
    t.integer  "user_id"
    t.datetime "approval_date"
    t.datetime "created_at",                   null: false
    t.datetime "updated_at",                   null: false
    t.boolean  "approved"
    t.boolean  "pending",       default: true
  end

  add_index "approvals", ["developer_id"], name: "index_approvals_on_developer_id", using: :btree
  add_index "approvals", ["user_id"], name: "index_approvals_on_user_id", using: :btree

  create_table "checkins", force: :cascade do |t|
    t.string   "status"
    t.float    "lat"
    t.float    "lng"
    t.string   "n_s"
    t.string   "e_w"
    t.float    "gspeed"
    t.float    "altitude"
    t.float    "course"
    t.string   "time"
    t.string   "date"
    t.float    "rotorspeed"
    t.string   "enginespeed"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.integer  "device_id"
    t.string   "address"
    t.string   "city"
    t.string   "postal_code"
    t.string   "country_code"
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.float  "latitude"
    t.float  "longitude"
    t.string "country_code"
  end

  create_table "developers", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "api_key"
    t.string   "company_name",                        null: false
    t.string   "logo_file_name"
    t.string   "logo_content_type"
    t.integer  "logo_file_size"
    t.datetime "logo_updated_at"
    t.string   "tagline"
  end

  add_index "developers", ["email"], name: "index_developers_on_email", unique: true, using: :btree
  add_index "developers", ["reset_password_token"], name: "index_developers_on_reset_password_token", unique: true, using: :btree

  create_table "device_developer_privileges", force: :cascade do |t|
    t.integer "developer_id"
    t.integer "device_id"
    t.integer "privilege"
  end

  add_index "device_developer_privileges", ["developer_id", "device_id"], name: "index_device_developer_privileges_on_developer_id_and_device_id", unique: true, using: :btree

  create_table "devices", force: :cascade do |t|
    t.string  "uuid"
    t.integer "user_id"
    t.string  "name"
    t.boolean "fogged",  default: false
    t.integer "delayed"
  end

  add_index "devices", ["uuid"], name: "index_devices_on_uuid", using: :btree

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
  end

  add_index "friendly_id_slugs", ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
  add_index "friendly_id_slugs", ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
  add_index "friendly_id_slugs", ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
  add_index "friendly_id_slugs", ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree

  create_table "requests", force: :cascade do |t|
    t.integer  "developer_id"
    t.datetime "created_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
    t.string   "connection_code"
    t.string   "username",                            null: false
    t.string   "slug"
    t.string   "authentication_token"
  end

  add_index "users", ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
  add_index "users", ["slug"], name: "index_users_on_slug", unique: true, using: :btree

end
