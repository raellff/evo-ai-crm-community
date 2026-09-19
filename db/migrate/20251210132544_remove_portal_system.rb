# frozen_string_literal: true

class RemovePortalSystem < ActiveRecord::Migration[7.0]
  def up
    # Remove foreign key constraint from inboxes first
    if foreign_key_exists?(:inboxes, :portals)
      remove_foreign_key :inboxes, :portals, if_exists: true
    end

    # Remove portal_id column from inboxes
    if column_exists?(:inboxes, :portal_id)
      remove_index :inboxes, :portal_id if index_exists?(:inboxes, :portal_id)
      remove_column :inboxes, :portal_id, if_exists: true
    end

    # Drop join table first
    drop_table :portals_members, if_exists: true

    # Drop related categories join table
    drop_table :related_categories, if_exists: true

    # Drop main tables
    drop_table :articles, if_exists: true
    drop_table :categories, if_exists: true
    drop_table :folders, if_exists: true
    drop_table :portals, if_exists: true
  end

  def down
    # Recreate portals table
    create_table :portals, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.string "slug", null: false
      t.string "custom_domain"
      t.string "color"
      t.string "homepage_link"
      t.string "page_title"
      t.text "header_text"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "config", default: {"allowed_locales" => ["en"]}
      t.boolean "archived", default: false
      t.boolean "channel_web_widget", default: false
      t.index ["custom_domain"], name: "index_portals_on_custom_domain", unique: true
      t.index ["slug"], name: "index_portals_on_slug", unique: true
    end

    # Recreate categories table
    create_table :categories, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "portal_id", null: false
      t.string "name"
      t.text "description"
      t.string "slug", null: false
      t.string "locale", default: "en"
      t.string "icon", default: ""
      t.integer "position"
      t.uuid "parent_category_id"
      t.uuid "associated_category_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["associated_category_id"], name: "index_categories_on_associated_category_id"
      t.index ["locale"], name: "index_categories_on_locale"
      t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
      t.index ["slug", "locale", "portal_id"], name: "index_categories_on_slug_and_locale_and_portal_id", unique: true
    end

    # Recreate folders table
    create_table :folders, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "category_id", null: false
      t.string "name"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    # Recreate articles table
    create_table :articles, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "portal_id", null: false
      t.uuid "category_id"
      t.uuid "folder_id"
      t.string "title"
      t.text "description"
      t.text "content"
      t.integer "status"
      t.integer "views"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.uuid "author_id"
      t.uuid "associated_article_id"
      t.jsonb "meta", default: {}
      t.string "slug", null: false
      t.integer "position"
      t.string "locale", default: "en", null: false
      t.index ["associated_article_id"], name: "index_articles_on_associated_article_id"
      t.index ["author_id"], name: "index_articles_on_author_id"
      t.index ["portal_id"], name: "index_articles_on_portal_id"
      t.index ["slug"], name: "index_articles_on_slug", unique: true
      t.index ["status"], name: "index_articles_on_status"
      t.index ["views"], name: "index_articles_on_views"
    end

    # Recreate related_categories table
    create_table :related_categories, id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "category_id"
      t.uuid "related_category_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["category_id", "related_category_id"], name: "index_related_categories_on_category_id_and_related_category_id", unique: true
      t.index ["related_category_id", "category_id"], name: "index_related_categories_on_related_category_id_and_category_id", unique: true
    end

    # Recreate portals_members table
    create_table :portals_members, id: false, force: :cascade do |t|
      t.uuid "portal_id", null: false
      t.uuid "user_id", null: false
      t.index ["portal_id", "user_id"], name: "index_portals_members_on_portal_id_and_user_id", unique: true
      t.index ["portal_id"], name: "index_portals_members_on_portal_id"
      t.index ["user_id"], name: "index_portals_members_on_user_id"
    end

    # Re-add portal_id to inboxes if needed
    unless column_exists?(:inboxes, :portal_id)
      add_column :inboxes, :portal_id, :uuid
      add_index :inboxes, :portal_id
      add_foreign_key :inboxes, :portals
    end
  end
end

