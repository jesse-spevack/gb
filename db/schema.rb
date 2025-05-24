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

ActiveRecord::Schema[8.0].define(version: 2025_05_24_021718) do
  create_table "assignment_summaries", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.integer "student_work_count", null: false
    t.text "qualitative_insights", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_assignment_summaries_on_assignment_id"
  end

  create_table "assignments", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "title", null: false
    t.string "subject"
    t.string "grade_level"
    t.text "instructions", null: false
    t.text "rubric_text"
    t.string "feedback_tone", default: "encouraging", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_assignments_on_user_id"
  end

  create_table "criteria", force: :cascade do |t|
    t.integer "rubric_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["rubric_id"], name: "index_criteria_on_rubric_id"
  end

  create_table "feedback_items", force: :cascade do |t|
    t.string "feedbackable_type", null: false
    t.integer "feedbackable_id", null: false
    t.integer "item_type", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.text "evidence", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["feedbackable_type", "feedbackable_id"], name: "index_feedback_items_on_feedbackable"
  end

  create_table "levels", force: :cascade do |t|
    t.integer "criterion_id", null: false
    t.string "title", null: false
    t.text "description", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["criterion_id"], name: "index_levels_on_criterion_id"
  end

  create_table "llm_usage_records", force: :cascade do |t|
    t.string "trackable_type", null: false
    t.integer "trackable_id", null: false
    t.integer "user_id", null: false
    t.integer "llm_provider"
    t.integer "request_type"
    t.integer "token_count"
    t.integer "micro_usd"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "llm_model", default: "", null: false
    t.index ["created_at"], name: "index_llm_usage_records_on_created_at"
    t.index ["llm_model"], name: "index_llm_usage_records_on_llm_model"
    t.index ["trackable_type", "trackable_id", "created_at"], name: "idx_on_trackable_type_trackable_id_created_at_83465e1418"
    t.index ["trackable_type", "trackable_id"], name: "index_llm_requests_on_trackable"
    t.index ["user_id", "created_at"], name: "index_llm_usage_records_on_user_id_and_created_at"
    t.index ["user_id"], name: "index_llm_usage_records_on_user_id"
  end

  create_table "processing_metrics", force: :cascade do |t|
    t.string "processable_type", null: false
    t.integer "processable_id", null: false
    t.datetime "completed_at"
    t.integer "duration_ms"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["processable_type", "processable_id"], name: "index_processing_metrics_on_processable"
  end

  create_table "rubrics", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_rubrics_on_assignment_id"
  end

  create_table "selected_documents", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.string "google_doc_id", null: false
    t.string "title", null: false
    t.string "url", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_selected_documents_on_assignment_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "user_agent", null: false
    t.string "ip_address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "student_criterion_levels", force: :cascade do |t|
    t.integer "student_work_id", null: false
    t.integer "criterion_id", null: false
    t.integer "level_id", null: false
    t.text "explanation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["criterion_id"], name: "index_student_criterion_levels_on_criterion_id"
    t.index ["level_id"], name: "index_student_criterion_levels_on_level_id"
    t.index ["student_work_id"], name: "index_student_criterion_levels_on_student_work_id"
  end

  create_table "student_work_checks", force: :cascade do |t|
    t.integer "student_work_id", null: false
    t.integer "check_type", null: false
    t.integer "score", null: false
    t.text "explanation", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["student_work_id"], name: "index_student_work_checks_on_student_work_id"
  end

  create_table "student_works", force: :cascade do |t|
    t.integer "assignment_id", null: false
    t.integer "selected_document_id", null: false
    t.text "qualitative_feedback"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_student_works_on_assignment_id"
    t.index ["selected_document_id"], name: "index_student_works_on_selected_document_id"
  end

  create_table "user_tokens", force: :cascade do |t|
    t.integer "user_id", null: false
    t.string "access_token", null: false
    t.string "refresh_token", null: false
    t.datetime "expires_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_user_tokens_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", null: false
    t.string "name", null: false
    t.string "google_uid", null: false
    t.string "profile_picture_url"
    t.boolean "admin", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["google_uid"], name: "index_users_on_google_uid", unique: true
  end

  add_foreign_key "assignment_summaries", "assignments"
  add_foreign_key "assignments", "users"
  add_foreign_key "criteria", "rubrics"
  add_foreign_key "levels", "criteria"
  add_foreign_key "llm_usage_records", "users"
  add_foreign_key "rubrics", "assignments"
  add_foreign_key "selected_documents", "assignments"
  add_foreign_key "sessions", "users"
  add_foreign_key "student_criterion_levels", "criteria"
  add_foreign_key "student_criterion_levels", "levels"
  add_foreign_key "student_criterion_levels", "student_works"
  add_foreign_key "student_work_checks", "student_works"
  add_foreign_key "student_works", "assignments"
  add_foreign_key "student_works", "selected_documents"
  add_foreign_key "user_tokens", "users"
end
