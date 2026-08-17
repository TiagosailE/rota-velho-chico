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

ActiveRecord::Schema[8.1].define(version: 2026_08_17_140100) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "bookings", force: :cascade do |t|
    t.integer "adults", default: 0, null: false
    t.datetime "cancelled_at"
    t.integer "children_0_4", default: 0, null: false
    t.integer "children_5_9", default: 0, null: false
    t.string "code", null: false
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.bigint "departure_id", null: false
    t.integer "deposit_cents", null: false
    t.integer "lunch_count", default: 0, null: false
    t.integer "lunch_unit_price_cents", default: 0, null: false
    t.integer "status", default: 0, null: false
    t.integer "total_cents", null: false
    t.integer "unit_price_cents", null: false
    t.datetime "updated_at", null: false
    t.index ["code"], name: "index_bookings_on_code", unique: true
    t.index ["customer_email"], name: "index_bookings_on_customer_email"
    t.index ["departure_id", "status"], name: "index_bookings_on_departure_id_and_status"
    t.check_constraint "(adults + children_5_9 + children_0_4) > 0", name: "bookings_party_not_empty"
    t.check_constraint "adults >= 0 AND children_5_9 >= 0 AND children_0_4 >= 0", name: "bookings_party_counts_non_negative"
    t.check_constraint "deposit_cents <= total_cents", name: "bookings_deposit_within_total"
    t.check_constraint "lunch_count <= (adults + children_5_9 + children_0_4)", name: "bookings_lunch_count_within_party"
    t.check_constraint "lunch_count >= 0", name: "bookings_lunch_count_non_negative"
    t.check_constraint "lunch_unit_price_cents >= 0", name: "bookings_lunch_unit_price_non_negative"
    t.check_constraint "unit_price_cents >= 0 AND total_cents >= 0 AND deposit_cents >= 0", name: "bookings_money_non_negative"
  end

  create_table "departures", force: :cascade do |t|
    t.integer "capacity", null: false
    t.datetime "created_at", null: false
    t.integer "price_override_cents"
    t.integer "seats_taken", default: 0, null: false
    t.datetime "starts_at", null: false
    t.integer "status", default: 0, null: false
    t.bigint "tour_id", null: false
    t.datetime "updated_at", null: false
    t.index ["starts_at"], name: "index_departures_on_starts_at"
    t.index ["tour_id", "starts_at"], name: "index_departures_on_tour_id_and_starts_at", unique: true
    t.check_constraint "capacity > 0", name: "departures_capacity_positive"
    t.check_constraint "price_override_cents IS NULL OR price_override_cents > 0", name: "departures_price_override_positive"
    t.check_constraint "seats_taken >= 0 AND seats_taken <= capacity", name: "departures_seats_within_capacity"
  end

  create_table "operators", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.text "bio"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.string "slug", null: false
    t.string "stripe_account_id"
    t.boolean "stripe_charges_enabled", default: false, null: false
    t.datetime "updated_at", null: false
    t.string "whatsapp"
    t.index ["email"], name: "index_operators_on_email", unique: true
    t.index ["reset_password_token"], name: "index_operators_on_reset_password_token", unique: true
    t.index ["slug"], name: "index_operators_on_slug", unique: true
    t.index ["stripe_account_id"], name: "index_operators_on_stripe_account_id", unique: true
  end

  create_table "payments", force: :cascade do |t|
    t.integer "amount_cents", null: false
    t.integer "application_fee_cents"
    t.bigint "booking_id", null: false
    t.datetime "created_at", null: false
    t.datetime "paid_at"
    t.integer "refunded_amount_cents"
    t.datetime "refunded_at"
    t.integer "status", default: 0, null: false
    t.string "stripe_checkout_session_id", null: false
    t.string "stripe_payment_intent_id"
    t.string "stripe_refund_id"
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_payments_on_booking_id", unique: true
    t.index ["stripe_checkout_session_id"], name: "index_payments_on_stripe_checkout_session_id", unique: true
    t.index ["stripe_payment_intent_id"], name: "index_payments_on_stripe_payment_intent_id", unique: true
    t.index ["stripe_refund_id"], name: "index_payments_on_stripe_refund_id", unique: true
    t.check_constraint "amount_cents >= 0", name: "payments_amount_non_negative"
    t.check_constraint "application_fee_cents IS NULL OR application_fee_cents >= 0", name: "payments_application_fee_non_negative"
    t.check_constraint "refunded_amount_cents IS NULL OR refunded_amount_cents >= 0 AND refunded_amount_cents <= amount_cents", name: "payments_refund_within_amount"
  end

  create_table "reviews", force: :cascade do |t|
    t.bigint "booking_id", null: false
    t.text "comment"
    t.datetime "created_at", null: false
    t.integer "rating", null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_reviews_on_booking_id", unique: true
    t.check_constraint "rating >= 1 AND rating <= 5", name: "reviews_rating_range"
  end

  create_table "stripe_events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "event_type", null: false
    t.datetime "processed_at"
    t.string "stripe_event_id", null: false
    t.datetime "updated_at", null: false
    t.index ["stripe_event_id"], name: "index_stripe_events_on_stripe_event_id", unique: true
  end

  create_table "tour_photos", force: :cascade do |t|
    t.string "alt_text"
    t.datetime "created_at", null: false
    t.integer "position", null: false
    t.bigint "tour_id", null: false
    t.datetime "updated_at", null: false
    t.index ["tour_id"], name: "index_tour_photos_on_tour_id"
    t.check_constraint "\"position\" >= 0", name: "tour_photos_position_non_negative"
    t.unique_constraint ["tour_id", "position"], deferrable: :immediate, name: "tour_photos_unique_position"
  end

  create_table "tours", force: :cascade do |t|
    t.boolean "active", default: true, null: false
    t.integer "base_price_cents", null: false
    t.integer "category", default: 0, null: false
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "duration_minutes", null: false
    t.decimal "lat", precision: 10, scale: 6
    t.decimal "lng", precision: 10, scale: 6
    t.integer "lunch_price_cents"
    t.string "meeting_point", null: false
    t.integer "min_age", default: 0, null: false
    t.bigint "operator_id", null: false
    t.string "slug", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["category"], name: "index_tours_on_category"
    t.index ["operator_id"], name: "index_tours_on_operator_id"
    t.index ["slug"], name: "index_tours_on_slug", unique: true
    t.check_constraint "base_price_cents > 0", name: "tours_base_price_positive"
    t.check_constraint "duration_minutes > 0", name: "tours_duration_positive"
    t.check_constraint "lat IS NULL OR lat >= '-90'::integer::numeric AND lat <= 90::numeric", name: "tours_lat_valid_range"
    t.check_constraint "lng IS NULL OR lng >= '-180'::integer::numeric AND lng <= 180::numeric", name: "tours_lng_valid_range"
    t.check_constraint "lunch_price_cents IS NULL OR lunch_price_cents > 0", name: "tours_lunch_price_positive"
    t.check_constraint "min_age >= 0", name: "tours_min_age_non_negative"
  end

  create_table "waitlist_entries", force: :cascade do |t|
    t.integer "adults", default: 0, null: false
    t.bigint "booking_id"
    t.integer "children_0_4", default: 0, null: false
    t.integer "children_5_9", default: 0, null: false
    t.datetime "created_at", null: false
    t.string "customer_email", null: false
    t.string "customer_name", null: false
    t.string "customer_phone"
    t.bigint "departure_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "updated_at", null: false
    t.index ["booking_id"], name: "index_waitlist_entries_on_booking_id", unique: true
    t.index ["departure_id", "status"], name: "index_waitlist_entries_on_departure_id_and_status"
    t.check_constraint "(adults + children_5_9 + children_0_4) > 0", name: "waitlist_entries_party_not_empty"
    t.check_constraint "adults >= 0 AND children_5_9 >= 0 AND children_0_4 >= 0", name: "waitlist_entries_party_counts_non_negative"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "bookings", "departures"
  add_foreign_key "departures", "tours"
  add_foreign_key "payments", "bookings"
  add_foreign_key "reviews", "bookings"
  add_foreign_key "tour_photos", "tours"
  add_foreign_key "tours", "operators"
  add_foreign_key "waitlist_entries", "bookings"
  add_foreign_key "waitlist_entries", "departures"
end
