# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_12_05_090612) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bans", id: :integer, default: nil, force: :cascade do |t|
    t.string "ip", default: -> { "nextval('bans_id_seq'::regclass)" }
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chats", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.text "chat"
    t.string "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "games", id: :serial, force: :cascade do |t|
    t.string "letters"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "guesses", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "game_id"
    t.string "word"
    t.integer "points"
  end

  create_table "locks", id: :serial, force: :cascade do |t|
    t.integer "lock"
  end

  create_table "scores", id: :serial, force: :cascade do |t|
    t.integer "user_id"
    t.integer "score_type"
    t.integer "count"
    t.float "cwords"
    t.float "pwords"
    t.float "cpoints"
    t.float "ppoints"
    t.integer "game_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.float "perfw"
    t.float "perfp"
    t.float "perfc"
  end

  create_table "solutions", id: :serial, force: :cascade do |t|
    t.string "word"
    t.integer "game_id"
    t.integer "points"
    t.index ["game_id", "word"], name: "index_solutions_on_game_id_and_word", unique: true
  end

  create_table "users", id: :serial, force: :cascade do |t|
    t.string "name", limit: 255
    t.integer "guest"
    t.string "password_digest", limit: 255
    t.string "remember_token", limit: 255
    t.integer "elo", default: 1600
    t.integer "new_elo", default: 1600
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer "game_id", default: 0
    t.string "email_digest"
    t.datetime "email_reset_date"
  end

  create_table "words", id: :serial, force: :cascade do |t|
    t.string "word", limit: 255
    t.index ["word"], name: "index_words_on_word", unique: true
    t.index ["word"], name: "index_words_on_word_wordlength"
  end

  create_table "words_new", id: :serial, force: :cascade do |t|
    t.string "word"
    t.index ["word"], name: "index_words_new_on_words", unique: true
  end

end
