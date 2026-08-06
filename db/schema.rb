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

ActiveRecord::Schema[8.1].define(version: 2026_07_27_170000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "customers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address"
    t.integer "lock_version", default: 0, null: false
    t.string "name", null: false
    t.text "notes"
    t.bigint "organization_id", null: false
    t.string "status", default: "active", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "email_address"], name: "index_customers_on_organization_id_and_email_address"
    t.index ["organization_id", "name"], name: "index_customers_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_customers_on_organization_id"
  end

  create_table "domain_events", force: :cascade do |t|
    t.bigint "actor_id"
    t.bigint "aggregate_id", null: false
    t.string "aggregate_type", null: false
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "occurred_at", null: false
    t.bigint "organization_id"
    t.jsonb "payload", default: {}, null: false
    t.string "request_id"
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_domain_events_on_actor_id"
    t.index ["aggregate_type", "aggregate_id", "occurred_at"], name: "index_domain_events_on_aggregate_and_time"
    t.index ["organization_id", "occurred_at"], name: "index_domain_events_on_organization_id_and_occurred_at"
    t.index ["organization_id"], name: "index_domain_events_on_organization_id"
  end

  create_table "feature_flags", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: false, null: false
    t.string "key", null: false
    t.jsonb "metadata", default: {}, null: false
    t.bigint "organization_id"
    t.datetime "updated_at", null: false
    t.index ["organization_id", "key"], name: "index_feature_flags_on_organization_id_and_key", unique: true
    t.index ["organization_id"], name: "index_feature_flags_on_organization_id"
  end

  create_table "grid_saved_views", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "default", default: false, null: false
    t.string "grid_key", null: false
    t.string "name", null: false
    t.jsonb "preferences", default: {}, null: false
    t.jsonb "query", default: {}, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id", "grid_key", "name"], name: "index_grid_saved_views_on_user_id_and_grid_key_and_name", unique: true
    t.index ["user_id", "grid_key"], name: "index_grid_saved_views_on_user_grid_default", unique: true, where: "(\"default\" = true)"
    t.index ["user_id"], name: "index_grid_saved_views_on_user_id"
  end

  create_table "idempotency_records", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "expires_at"
    t.string "key", null: false
    t.jsonb "result", default: {}, null: false
    t.string "scope", default: "default", null: false
    t.string "status", default: "started", null: false
    t.datetime "updated_at", null: false
    t.index ["scope", "key"], name: "index_idempotency_records_on_scope_and_key", unique: true
  end

  create_table "import_runs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.jsonb "error_details", default: [], null: false
    t.integer "failed_rows", default: 0, null: false
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.integer "processed_rows", default: 0, null: false
    t.bigint "requested_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_import_runs_on_organization_id"
    t.index ["requested_by_id"], name: "index_import_runs_on_requested_by_id"
  end

  create_table "installation_records", force: :cascade do |t|
    t.integer "contract_version", null: false
    t.datetime "created_at", null: false
    t.string "environment", null: false
    t.jsonb "metadata", default: {}, null: false
    t.string "schema_version", null: false
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["environment", "created_at"], name: "index_installation_records_on_environment_and_created_at"
    t.check_constraint "status::text = ANY (ARRAY['migrated'::character varying, 'owner_created'::character varying, 'completed'::character varying]::text[])", name: "installation_records_status"
  end

  create_table "memberships", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "organization_id", null: false
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id"], name: "index_memberships_on_organization_id_and_user_id", unique: true
    t.index ["organization_id"], name: "index_memberships_on_organization_id"
    t.index ["user_id"], name: "index_memberships_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "delivered_at"
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.jsonb "payload", default: {}, null: false
    t.bigint "recipient_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_notifications_on_organization_id"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "organization_invitations", force: :cascade do |t|
    t.datetime "accepted_at"
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.bigint "invited_by_id", null: false
    t.bigint "organization_id", null: false
    t.datetime "revoked_at"
    t.string "role", default: "member", null: false
    t.datetime "updated_at", null: false
    t.index ["invited_by_id"], name: "index_organization_invitations_on_invited_by_id"
    t.index ["organization_id", "email_address"], name: "index_pending_organization_invitations", unique: true, where: "((accepted_at IS NULL) AND (revoked_at IS NULL))"
    t.index ["organization_id"], name: "index_organization_invitations_on_organization_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "locale", default: "en", null: false
    t.string "name", null: false
    t.string "slug", null: false
    t.string "theme", default: "system", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_organizations_on_slug", unique: true
    t.check_constraint "theme::text = ANY (ARRAY['light'::character varying, 'dark'::character varying, 'system'::character varying]::text[])", name: "organizations_theme_check"
  end

  create_table "platform_roles", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "role", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_platform_roles_on_user_id", unique: true
    t.check_constraint "role::text = 'platform_admin'::text", name: "platform_roles_role"
  end

  create_table "privacy_preferences", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.datetime "decided_at", null: false
    t.boolean "granted", default: false, null: false
    t.bigint "organization_id", null: false
    t.string "purpose", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["organization_id", "user_id", "purpose"], name: "index_privacy_preferences_unique", unique: true
    t.index ["organization_id"], name: "index_privacy_preferences_on_organization_id"
    t.index ["user_id"], name: "index_privacy_preferences_on_user_id"
  end

  create_table "privacy_requests", force: :cascade do |t|
    t.datetime "completed_at"
    t.datetime "created_at", null: false
    t.text "failure_reason"
    t.string "kind", null: false
    t.bigint "organization_id", null: false
    t.bigint "requested_by_id", null: false
    t.jsonb "result", default: {}, null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_privacy_requests_on_organization_id"
    t.index ["requested_by_id"], name: "index_privacy_requests_on_requested_by_id"
    t.check_constraint "kind::text = ANY (ARRAY['export'::character varying, 'anonymize'::character varying]::text[])", name: "privacy_requests_kind_check"
    t.check_constraint "status::text = ANY (ARRAY['pending'::character varying, 'processing'::character varying, 'completed'::character varying, 'failed'::character varying]::text[])", name: "privacy_requests_status_check"
  end

  create_table "retention_policies", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.bigint "organization_id", null: false
    t.string "record_type", null: false
    t.integer "retention_days", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "record_type"], name: "index_retention_policies_on_organization_id_and_record_type", unique: true
    t.index ["organization_id"], name: "index_retention_policies_on_organization_id"
    t.check_constraint "retention_days > 0", name: "retention_policies_positive_days"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address", limit: 45
    t.datetime "updated_at", null: false
    t.string "user_agent", limit: 512
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "stored_files", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum", null: false
    t.string "content_type", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "organization_id", null: false
    t.string "storage_key", null: false
    t.datetime "updated_at", null: false
    t.bigint "uploaded_by_id"
    t.index ["organization_id"], name: "index_stored_files_on_organization_id"
    t.index ["storage_key"], name: "index_stored_files_on_storage_key", unique: true
    t.index ["uploaded_by_id"], name: "index_stored_files_on_uploaded_by_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "locale", default: "en", null: false
    t.string "password_digest", null: false
    t.string "time_zone", default: "UTC", null: false
    t.datetime "updated_at", null: false
    t.index "lower((email_address)::text)", name: "index_users_on_lower_email_address", unique: true
  end

  create_table "webhook_endpoints", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.boolean "enabled", default: true, null: false
    t.jsonb "events", default: [], null: false
    t.bigint "organization_id", null: false
    t.string "secret", null: false
    t.datetime "updated_at", null: false
    t.string "url", null: false
    t.index ["organization_id"], name: "index_webhook_endpoints_on_organization_id"
  end

  add_foreign_key "customers", "organizations"
  add_foreign_key "domain_events", "organizations"
  add_foreign_key "domain_events", "users", column: "actor_id"
  add_foreign_key "feature_flags", "organizations"
  add_foreign_key "grid_saved_views", "users"
  add_foreign_key "import_runs", "organizations"
  add_foreign_key "import_runs", "users", column: "requested_by_id"
  add_foreign_key "memberships", "organizations"
  add_foreign_key "memberships", "users"
  add_foreign_key "notifications", "organizations"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "organization_invitations", "organizations"
  add_foreign_key "organization_invitations", "users", column: "invited_by_id"
  add_foreign_key "platform_roles", "users"
  add_foreign_key "privacy_preferences", "organizations"
  add_foreign_key "privacy_preferences", "users"
  add_foreign_key "privacy_requests", "organizations"
  add_foreign_key "privacy_requests", "users", column: "requested_by_id"
  add_foreign_key "retention_policies", "organizations"
  add_foreign_key "sessions", "users"
  add_foreign_key "stored_files", "organizations"
  add_foreign_key "stored_files", "users", column: "uploaded_by_id"
  add_foreign_key "webhook_endpoints", "organizations"
end
