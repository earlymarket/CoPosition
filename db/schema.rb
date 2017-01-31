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

ActiveRecord::Schema.define(version: 20170120161207) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.string   "author_type"
    t.integer  "author_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
    t.index ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
    t.index ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree
  end

  create_table "approvals", force: :cascade do |t|
    t.integer  "approvable_id"
    t.integer  "user_id"
    t.datetime "approval_date"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "status"
    t.string   "approvable_type"
    t.index ["approvable_id"], name: "index_approvals_on_approvable_id", using: :btree
    t.index ["user_id"], name: "index_approvals_on_user_id", using: :btree
  end

  create_table "attachinary_files", force: :cascade do |t|
    t.string   "attachinariable_type"
    t.integer  "attachinariable_id"
    t.string   "scope"
    t.string   "public_id"
    t.string   "version"
    t.integer  "width"
    t.integer  "height"
    t.string   "format"
    t.string   "resource_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["attachinariable_type", "attachinariable_id", "scope"], name: "by_scoped_parent", using: :btree
  end

  create_table "checkins", force: :cascade do |t|
    t.float    "lat"
    t.float    "lng"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "uuid"
    t.integer  "device_id"
    t.string   "address",             default: "Not yet geocoded"
    t.string   "city"
    t.string   "postal_code"
    t.string   "country_code"
    t.boolean  "fogged"
    t.float    "fogged_lat"
    t.float    "fogged_lng"
    t.string   "fogged_city"
    t.float    "output_lat"
    t.float    "output_lng"
    t.string   "output_address"
    t.string   "output_city"
    t.string   "output_postal_code"
    t.string   "output_country_code"
    t.string   "fogged_country_code"
    t.boolean  "edited",              default: false
    t.index ["device_id"], name: "index_checkins_on_device_id", using: :btree
  end

  create_table "cities", force: :cascade do |t|
    t.string "name"
    t.float  "latitude"
    t.float  "longitude"
    t.string "country_code"
    t.index ["latitude", "longitude"], name: "index_cities_on_latitude_and_longitude", using: :btree
  end

  create_table "configs", force: :cascade do |t|
    t.integer  "developer_id"
    t.integer  "device_id"
    t.text     "custom"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
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
    t.string   "tagline"
    t.string   "redirect_url"
    t.index ["email"], name: "index_developers_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_developers_on_reset_password_token", unique: true, using: :btree
  end

  create_table "devices", force: :cascade do |t|
    t.string  "uuid"
    t.integer "user_id"
    t.string  "name"
    t.boolean "fogged",    default: true
    t.integer "delayed"
    t.string  "alias"
    t.boolean "published", default: false
    t.boolean "cloaked",   default: false
    t.index ["uuid"], name: "index_devices_on_uuid", using: :btree
  end

  create_table "friendly_id_slugs", force: :cascade do |t|
    t.string   "slug",                      null: false
    t.integer  "sluggable_id",              null: false
    t.string   "sluggable_type", limit: 50
    t.string   "scope"
    t.datetime "created_at"
    t.index ["slug", "sluggable_type", "scope"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type_and_scope", unique: true, using: :btree
    t.index ["slug", "sluggable_type"], name: "index_friendly_id_slugs_on_slug_and_sluggable_type", using: :btree
    t.index ["sluggable_id"], name: "index_friendly_id_slugs_on_sluggable_id", using: :btree
    t.index ["sluggable_type"], name: "index_friendly_id_slugs_on_sluggable_type", using: :btree
  end

  create_table "permissions", force: :cascade do |t|
    t.integer "permissible_id"
    t.integer "device_id"
    t.integer "privilege"
    t.string  "permissible_type"
    t.boolean "bypass_fogging",   default: false
    t.boolean "bypass_delay",     default: false
  end

  create_table "requests", force: :cascade do |t|
    t.integer  "developer_id"
    t.datetime "created_at"
    t.boolean  "paid",         default: false
    t.integer  "user_id"
    t.string   "action"
    t.string   "controller"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.integer  "subscriber_id"
    t.string   "target_url"
    t.string   "event"
    t.datetime "created_at",      null: false
    t.datetime "updated_at",      null: false
    t.string   "subscriber_type"
  end

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "",    null: false
    t.string   "encrypted_password",     default: "",    null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,     null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                             null: false
    t.datetime "updated_at",                             null: false
    t.string   "connection_code"
    t.string   "username",                               null: false
    t.string   "slug"
    t.string   "authentication_token"
    t.string   "webhook_key"
    t.boolean  "admin",                  default: false, null: false
    t.index ["authentication_token"], name: "index_users_on_authentication_token", using: :btree
    t.index ["email"], name: "index_users_on_email", unique: true, using: :btree
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree
    t.index ["slug"], name: "index_users_on_slug", unique: true, using: :btree
    t.index ["webhook_key"], name: "index_users_on_webhook_key", unique: true, using: :btree
  end

end
