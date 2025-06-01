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

ActiveRecord::Schema[7.1].define(version: 2025_06_01_024355) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.string "status"
    t.date "date"
    t.time "time"
    t.bigint "profile_id", null: false
    t.bigint "service_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attended_by"
    t.index ["branch_id"], name: "index_attendances_on_branch_id"
    t.index ["organization_id"], name: "index_attendances_on_organization_id"
    t.index ["profile_id"], name: "index_attendances_on_profile_id"
    t.index ["service_id"], name: "index_attendances_on_service_id"
  end

  create_table "branch_users", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_branch_users_on_branch_id"
    t.index ["user_id"], name: "index_branch_users_on_user_id"
  end

  create_table "branches", force: :cascade do |t|
    t.string "name"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.string "phone_number"
    t.string "email"
    t.boolean "active"
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_branches_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.json "metadata"
    t.string "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.date "birth_date"
    t.string "phone_number"
    t.bigint "organization_id", null: false
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_profiles_on_branch_id"
    t.index ["organization_id"], name: "index_profiles_on_organization_id"
  end

  create_table "roles", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "organization_id", null: false
    t.bigint "branch_id", null: false
    t.boolean "is_admin"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_roles_on_branch_id"
    t.index ["organization_id"], name: "index_roles_on_organization_id"
  end

  create_table "services", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.bigint "organization_id", null: false
    t.decimal "price"
    t.bigint "branch_id", null: false
    t.integer "duration"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_services_on_branch_id"
    t.index ["organization_id"], name: "index_services_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone_number"
    t.string "address_line1"
    t.string "address_line2"
    t.string "city"
    t.string "state"
    t.string "zip_code"
    t.string "country"
    t.boolean "active"
    t.string "password_digest"
    t.bigint "role_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_working_at"
    t.string "work_state"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "attendances", "branches"
  add_foreign_key "attendances", "organizations"
  add_foreign_key "attendances", "profiles"
  add_foreign_key "attendances", "services"
  add_foreign_key "attendances", "users", column: "attended_by"
  add_foreign_key "branch_users", "branches"
  add_foreign_key "branch_users", "users"
  add_foreign_key "branches", "organizations"
  add_foreign_key "profiles", "branches"
  add_foreign_key "profiles", "organizations"
  add_foreign_key "roles", "branches"
  add_foreign_key "roles", "organizations"
  add_foreign_key "services", "branches"
  add_foreign_key "services", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
end
