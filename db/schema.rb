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

ActiveRecord::Schema[7.1].define(version: 2025_07_11_140932) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "attendances", force: :cascade do |t|
    t.string "status"
    t.date "date"
    t.time "time"
    t.bigint "profile_id", null: false
    t.bigint "organization_id", null: false
    t.bigint "branch_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "attended_by"
    t.integer "discount"
    t.integer "extra_discount"
    t.integer "user_amount"
    t.integer "organization_amount"
    t.datetime "start_attendance_at", precision: nil
    t.datetime "end_attendance_at", precision: nil
    t.integer "total_amount"
    t.string "trx_number"
    t.string "payment_method"
    t.integer "parent_attendance_id"
    t.text "comments"
    t.integer "tip_amount"
    t.string "nid"
    t.index ["branch_id"], name: "index_attendances_on_branch_id"
    t.index ["date", "nid"], name: "index_attendances_on_date_and_nid", unique: true
    t.index ["organization_id"], name: "index_attendances_on_organization_id"
    t.index ["parent_attendance_id"], name: "index_attendances_on_parent_attendance_id"
    t.index ["profile_id", "status"], name: "unique_active_attendance_per_profile", unique: true, where: "((status)::text = ANY ((ARRAY['pending'::character varying, 'processing'::character varying, 'postponed'::character varying])::text[]))"
    t.index ["profile_id"], name: "index_attendances_on_profile_id"
  end

  create_table "attendances_services", id: false, force: :cascade do |t|
    t.bigint "attendance_id", null: false
    t.bigint "service_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
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
    t.string "photo_url"
    t.index ["organization_id"], name: "index_branches_on_organization_id"
  end

  create_table "cash_reconciliations", force: :cascade do |t|
    t.integer "reconciliation_type", default: 0, null: false
    t.decimal "cash_amount", precision: 10, scale: 2, default: "0.0"
    t.jsonb "bank_balances", default: []
    t.decimal "total_calculated", precision: 10, scale: 2, default: "0.0"
    t.decimal "expected_cash", precision: 10, scale: 2
    t.decimal "expected_bank_transfer", precision: 10, scale: 2
    t.decimal "expected_credit_card", precision: 10, scale: 2
    t.decimal "difference_cash", precision: 10, scale: 2
    t.integer "status", default: 0
    t.text "notes"
    t.bigint "user_id", null: false
    t.bigint "branch_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "difference_pos", precision: 10, scale: 2
    t.decimal "difference_transfer", precision: 10, scale: 2
    t.datetime "approved_at"
    t.bigint "approved_by_user_id"
    t.index ["approved_by_user_id"], name: "index_cash_reconciliations_on_approved_by_user_id"
    t.index ["branch_id"], name: "index_cash_reconciliations_on_branch_id"
    t.index ["organization_id"], name: "index_cash_reconciliations_on_organization_id"
    t.index ["reconciliation_type"], name: "index_cash_reconciliations_on_reconciliation_type"
    t.index ["status"], name: "index_cash_reconciliations_on_status"
    t.index ["user_id"], name: "index_cash_reconciliations_on_user_id"
  end

  create_table "expenses", force: :cascade do |t|
    t.string "description"
    t.decimal "amount"
    t.bigint "organization_id", null: false
    t.bigint "user_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "branch_id", null: false
    t.integer "quantity"
    t.string "type"
    t.index ["branch_id"], name: "index_expenses_on_branch_id"
    t.index ["organization_id"], name: "index_expenses_on_organization_id"
    t.index ["user_id"], name: "index_expenses_on_user_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name"
    t.string "slug"
    t.json "metadata"
    t.string "bio"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_url"
    t.string "qr_code"
  end

  create_table "payments", force: :cascade do |t|
    t.float "amount", null: false
    t.bigint "organization_id", null: false
    t.bigint "branch_id", null: false
    t.bigint "user_id", null: false
    t.string "aasm_state", default: "pending", null: false
    t.datetime "starts_at", precision: nil, null: false
    t.datetime "ends_at", precision: nil, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["branch_id"], name: "index_payments_on_branch_id"
    t.index ["organization_id"], name: "index_payments_on_organization_id"
    t.index ["user_id"], name: "index_payments_on_user_id"
  end

  create_table "profiles", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.date "birth_date"
    t.string "phone_number"
    t.bigint "organization_id", null: false
    t.bigint "branch_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "photo_url"
    t.datetime "last_attendance_at", precision: nil
    t.index ["branch_id"], name: "index_profiles_on_branch_id"
    t.index ["organization_id"], name: "index_profiles_on_organization_id"
  end

  create_table "push_subscriptions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.jsonb "subscription_data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_push_subscriptions_on_user_id"
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
    t.string "photo_url"
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
    t.boolean "active", default: true
    t.string "password_digest"
    t.bigint "role_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "start_working_at"
    t.string "work_state"
    t.integer "branch_id"
    t.string "photo_url"
    t.string "email_verification_code"
    t.boolean "email_verified"
    t.index ["branch_id"], name: "index_users_on_branch_id"
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["role_id"], name: "index_users_on_role_id"
  end

  add_foreign_key "attendances", "branches"
  add_foreign_key "attendances", "organizations"
  add_foreign_key "attendances", "profiles"
  add_foreign_key "attendances", "users", column: "attended_by"
  add_foreign_key "branch_users", "branches"
  add_foreign_key "branch_users", "users"
  add_foreign_key "branches", "organizations"
  add_foreign_key "cash_reconciliations", "branches"
  add_foreign_key "cash_reconciliations", "organizations"
  add_foreign_key "cash_reconciliations", "users"
  add_foreign_key "cash_reconciliations", "users", column: "approved_by_user_id"
  add_foreign_key "expenses", "branches"
  add_foreign_key "expenses", "organizations"
  add_foreign_key "expenses", "users"
  add_foreign_key "payments", "branches"
  add_foreign_key "payments", "organizations"
  add_foreign_key "payments", "users"
  add_foreign_key "profiles", "branches"
  add_foreign_key "profiles", "organizations"
  add_foreign_key "push_subscriptions", "users"
  add_foreign_key "roles", "branches"
  add_foreign_key "roles", "organizations"
  add_foreign_key "services", "branches"
  add_foreign_key "services", "organizations"
  add_foreign_key "users", "organizations"
  add_foreign_key "users", "roles"
end
