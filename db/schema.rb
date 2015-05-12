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

ActiveRecord::Schema.define(version: 20150512084954) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "bans", force: true do |t|
    t.string   "ip"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "chats", force: true do |t|
    t.integer  "user_id"
    t.text     "chat"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "ip"
  end

  create_table "games", force: true do |t|
    t.string   "letters"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "guesses", force: true do |t|
    t.integer "user_id"
    t.integer "game_id"
    t.string  "word"
    t.integer "points"
  end

  add_index "guesses", ["game_id", "user_id", "word"], name: "index_guesses_on_game_id_and_user_id_and_word", unique: true, using: :btree

  create_table "locks", force: true do |t|
    t.integer "lock"
  end

  add_index "locks", ["lock"], name: "index_locks_on_lock", unique: true, using: :btree

  create_table "scores", force: true do |t|
    t.integer  "user_id"
    t.integer  "score_type"
    t.integer  "count"
    t.float    "cwords"
    t.float    "pwords"
    t.float    "cpoints"
    t.float    "ppoints"
    t.integer  "game_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "solutions", force: true do |t|
    t.string  "word"
    t.integer "game_id"
    t.integer "points"
  end

  add_index "solutions", ["game_id", "word"], name: "index_solutions_on_game_id_and_word", unique: true, using: :btree

  create_table "users", force: true do |t|
    t.string   "name"
    t.integer  "guest"
    t.string   "password_digest"
    t.string   "remember_token"
    t.integer  "elo",             default: 1600
    t.integer  "new_elo",         default: 1600
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "game_id",         default: 0
  end

  create_table "words", force: true do |t|
    t.string "word"
  end

  add_index "words", ["word"], name: "index_words_on_word", unique: true, using: :btree
  add_index "words", ["word"], name: "index_words_on_word_wordlength", using: :btree

  create_table "words_new", force: true do |t|
    t.string "word"
  end

  add_index "words_new", ["word"], name: "index_words_new_on_word", unique: true, using: :btree

end
