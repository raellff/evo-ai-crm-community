class InitSchema < ActiveRecord::Migration[6.1]
  def up
    # These are extensions that must be enabled in order to support this database
    enable_extension "pg_stat_statements"
    enable_extension "pg_trgm"
    enable_extension "pgcrypto"
    enable_extension "plpgsql"
    enable_extension "uuid-ossp"

    create_table "action_mailbox_inbound_emails", force: :cascade do |t|
      t.integer "status", default: 0, null: false
      t.string "message_id", null: false
      t.string "message_checksum", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["message_id", "message_checksum"], name: "index_action_mailbox_inbound_emails_uniqueness", unique: true
    end

    create_table "agent_bot_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "inbox_id"
      t.uuid "agent_bot_id"
      t.integer "status", default: 0
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "agent_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.string "description"
      t.string "outgoing_url"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "bot_type", default: 0
      t.jsonb "bot_config", default: {}
      t.string "api_key"
      t.string "bot_provider", default: "webhook", null: false
      t.text "message_signature"
      t.boolean "text_segmentation_enabled", default: false, null: false
      t.integer "text_segmentation_limit", default: 300
      t.integer "text_segmentation_min_size", default: 50
      t.decimal "delay_per_character", precision: 8, scale: 2, default: "50.0"
      t.integer "debounce_time", default: 5, null: false
      t.uuid "account_id"
    end

    create_table "alembic_version", primary_key: "version_num", id: { type: :string, limit: 32 }, force: :cascade do |t|
    end

    create_table "app_states", primary_key: "app_name", id: { type: :string, limit: 128 }, force: :cascade do |t|
      t.jsonb "state", null: false
      t.datetime "update_time", precision: nil, null: false
    end

    create_table "applied_slas", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "sla_policy_id", null: false
      t.uuid "conversation_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.integer "sla_status", default: 0
      t.index ["sla_policy_id", "conversation_id"], name: "index_applied_slas_on_sla_policy_conversation", unique: true
      t.index ["conversation_id"], name: "index_applied_slas_on_conversation_id"
      t.index ["sla_policy_id"], name: "index_applied_slas_on_sla_policy_id"
    end

    create_table "articles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
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

    create_table "attachments", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.integer "file_type", default: 0
      t.string "external_url"
      t.float "coordinates_lat", default: 0.0
      t.float "coordinates_long", default: 0.0
      t.uuid "message_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "fallback_title"
      t.string "extension"
      t.jsonb "meta", default: {}
      t.index ["message_id"], name: "index_attachments_on_message_id"
    end

    create_table "audits", force: :cascade do |t|
      t.uuid "auditable_id"
      t.string "auditable_type"
      t.uuid "associated_id"
      t.string "associated_type"
      t.uuid "user_id"
      t.string "user_type"
      t.string "username"
      t.string "action"
      t.jsonb "audited_changes"
      t.integer "version", default: 0
      t.string "comment"
      t.string "remote_address"
      t.string "request_uuid"
      t.datetime "created_at", precision: nil
      t.index ["associated_type", "associated_id"], name: "associated_index"
      t.index ["auditable_type", "auditable_id", "version"], name: "auditable_index"
      t.index ["created_at"], name: "index_audits_on_created_at"
      t.index ["request_uuid"], name: "index_audits_on_request_uuid"
      t.index ["user_id", "user_type"], name: "user_index"
    end

    create_table "automation_rules", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.text "description"
      t.string "event_name", null: false
      t.jsonb "conditions", default: "{}", null: false
      t.jsonb "actions", default: "{}", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "active", default: true, null: false
      t.string "mode", default: "simple", null: false
      t.jsonb "flow_data"
      t.index ["flow_data"], name: "index_automation_rules_on_flow_data", using: :gin
      t.index ["mode"], name: "index_automation_rules_on_mode"
    end


    create_table "canned_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "short_code"
      t.text "content"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "portal_id", null: false
      t.string "name"
      t.text "description"
      t.integer "position"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "locale", default: "en"
      t.string "slug", null: false
      t.uuid "parent_category_id"
      t.uuid "associated_category_id"
      t.string "icon", default: ""
      t.index ["associated_category_id"], name: "index_categories_on_associated_category_id"
      t.index ["locale"], name: "index_categories_on_locale"
      t.index ["parent_category_id"], name: "index_categories_on_parent_category_id"
      t.index ["slug", "locale", "portal_id"], name: "index_categories_on_slug_and_locale_and_portal_id", unique: true
    end

    create_table "channel_api", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "webhook_url"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "identifier"
      t.string "hmac_token"
      t.boolean "hmac_mandatory", default: false
      t.jsonb "additional_attributes", default: {}
      t.index ["hmac_token"], name: "index_channel_api_on_hmac_token", unique: true
      t.index ["identifier"], name: "index_channel_api_on_identifier", unique: true
    end

    create_table "channel_email", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "email", null: false
      t.string "forward_to_email", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "imap_enabled", default: false
      t.string "imap_address", default: ""
      t.integer "imap_port", default: 0
      t.string "imap_login", default: ""
      t.string "imap_password", default: ""
      t.boolean "imap_enable_ssl", default: true
      t.boolean "smtp_enabled", default: false
      t.string "smtp_address", default: ""
      t.integer "smtp_port", default: 0
      t.string "smtp_login", default: ""
      t.string "smtp_password", default: ""
      t.string "smtp_domain", default: ""
      t.boolean "smtp_enable_starttls_auto", default: true
      t.string "smtp_authentication", default: "login"
      t.string "smtp_openssl_verify_mode", default: "none"
      t.boolean "smtp_enable_ssl_tls", default: false
      t.jsonb "provider_config", default: {}
      t.string "provider"
      t.index ["email"], name: "index_channel_email_on_email", unique: true
      t.index ["forward_to_email"], name: "index_channel_email_on_forward_to_email", unique: true
    end

    create_table "channel_facebook_pages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "page_id", null: false
      t.string "user_access_token", null: false
      t.string "page_access_token", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "instagram_id"
      t.jsonb "message_templates", default: []
      t.datetime "message_templates_last_updated"
      t.index ["page_id"], name: "index_channel_facebook_pages_on_page_id", unique: true
    end

    create_table "channel_instagram", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "access_token", null: false
      t.datetime "expires_at", null: false
      t.string "instagram_id", null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.jsonb "message_templates", default: []
      t.datetime "message_templates_last_updated"
      t.index ["instagram_id"], name: "index_channel_instagram_on_instagram_id", unique: true
    end

    create_table "channel_line", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "line_channel_id", null: false
      t.string "line_channel_secret", null: false
      t.string "line_channel_token", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "message_templates", default: []
      t.datetime "message_templates_last_updated"
      t.index ["line_channel_id"], name: "index_channel_line_on_line_channel_id", unique: true
    end

    create_table "channel_sms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "phone_number", null: false
      t.string "provider", default: "default"
      t.jsonb "provider_config", default: {}
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["phone_number"], name: "index_channel_sms_on_phone_number", unique: true
    end

    create_table "channel_telegram", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "bot_name"
      t.string "bot_token", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "message_templates", default: []
      t.datetime "message_templates_last_updated"
      t.index ["bot_token"], name: "index_channel_telegram_on_bot_token", unique: true
    end

    create_table "channel_twilio_sms", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "phone_number"
      t.string "auth_token", null: false
      t.string "account_sid", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "medium", default: 0
      t.string "messaging_service_sid"
      t.string "api_key_sid"
      t.jsonb "message_templates", default: []
      t.datetime "message_templates_last_updated"
      t.index ["account_sid", "phone_number"], name: "index_channel_twilio_sms_on_account_sid_and_phone_number", unique: true
      t.index ["messaging_service_sid"], name: "index_channel_twilio_sms_on_messaging_service_sid", unique: true
      t.index ["phone_number"], name: "index_channel_twilio_sms_on_phone_number", unique: true
    end

    create_table "channel_twitter_profiles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "profile_id", null: false
      t.string "twitter_access_token", null: false
      t.string "twitter_access_token_secret", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "tweets_enabled", default: true
      t.index ["profile_id"], name: "index_channel_twitter_profiles_on_profile_id", unique: true
    end

    create_table "channel_web_widgets", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "website_url"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "website_token"
      t.string "widget_color", default: "#1f93ff"
      t.string "welcome_title"
      t.string "welcome_tagline"
      t.integer "feature_flags", default: 7, null: false
      t.integer "reply_time", default: 0
      t.string "hmac_token"
      t.boolean "pre_chat_form_enabled", default: false
      t.jsonb "pre_chat_form_options", default: {}
      t.boolean "hmac_mandatory", default: false
      t.boolean "continuity_via_email", default: true, null: false
      t.index ["hmac_token"], name: "index_channel_web_widgets_on_hmac_token", unique: true
      t.index ["website_token"], name: "index_channel_web_widgets_on_website_token", unique: true
    end

    create_table "channel_whatsapp", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "phone_number", null: false
      t.string "provider", default: "default"
      t.jsonb "provider_config", default: {}
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "message_templates", default: {}
      t.datetime "message_templates_last_updated", precision: nil
      t.jsonb "provider_connection", default: {}
      t.index ["phone_number"], name: "index_channel_whatsapp_on_phone_number", unique: true
    end

    create_table "contact_inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "contact_id"
      t.uuid "inbox_id"
      t.string "source_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "hmac_verified", default: false
      t.string "pubsub_token"
      t.index ["contact_id"], name: "index_contact_inboxes_on_contact_id"
      t.index ["inbox_id", "source_id"], name: "index_contact_inboxes_on_inbox_id_and_source_id", unique: true
      t.index ["inbox_id"], name: "index_contact_inboxes_on_inbox_id"
      t.index ["pubsub_token"], name: "index_contact_inboxes_on_pubsub_token", unique: true
      t.index ["source_id"], name: "index_contact_inboxes_on_source_id"
    end

    unless table_exists?(:contacts)
      create_table "contacts", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string "name", default: ""
        t.string "email"
        t.string "phone_number"
        t.datetime "created_at", precision: nil, null: false
        t.datetime "updated_at", precision: nil, null: false
        t.jsonb "additional_attributes", default: {}
        t.string "identifier"
        t.jsonb "custom_attributes", default: {}
        t.datetime "last_activity_at", precision: nil
        t.integer "contact_type", default: 0
        t.string "middle_name", default: ""
        t.string "last_name", default: ""
        t.string "location", default: ""
        t.string "country_code", default: ""
        t.boolean "blocked", default: false, null: false
        t.uuid "account_id"
        t.index ["blocked"], name: "index_contacts_on_blocked"
        t.index ["email"], name: "uniq_email_per_account_contact", unique: true
        t.index ["identifier"], name: "uniq_identifier_per_account_contact", unique: true
        t.index ["last_activity_at"], name: "index_contacts_on_last_activity_at", order: { last_activity_at: "DESC NULLS LAST" }
        t.index ["name", "email", "phone_number", "identifier"], name: "index_contacts_on_name_email_phone_number_identifier", opclass: :gin_trgm_ops, using: :gin
        t.index ["phone_number"], name: "index_contacts_on_phone_number"
      end
    end

    create_table "conversation_participants", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.uuid "conversation_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["conversation_id"], name: "index_conversation_participants_on_conversation_id"
      t.index ["user_id", "conversation_id"], name: "index_conversation_participants_on_user_id_and_conversation_id", unique: true
      t.index ["user_id"], name: "index_conversation_participants_on_user_id"
    end

    create_table "conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "inbox_id", null: false
      t.integer "status", default: 0, null: false
      t.uuid "assignee_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.uuid "contact_id"
      t.integer "display_id", null: false
      t.datetime "contact_last_seen_at", precision: nil
      t.datetime "agent_last_seen_at", precision: nil
      t.jsonb "additional_attributes", default: {}
      t.uuid "contact_inbox_id"
      t.uuid "uuid", default: -> { "gen_random_uuid()" }, null: false
      t.string "identifier"
      t.datetime "last_activity_at", precision: nil, default: -> { "CURRENT_TIMESTAMP" }, null: false
      t.uuid "team_id"
      t.datetime "snoozed_until", precision: nil
      t.jsonb "custom_attributes", default: {}
      t.datetime "assignee_last_seen_at", precision: nil
      t.datetime "first_reply_created_at", precision: nil
      t.integer "priority"
      t.datetime "waiting_since"
      t.text "cached_label_list"
      t.uuid "sla_policy_id"
      t.uuid "account_id"
      t.index ["assignee_id", "status", "last_activity_at"], name: "index_conversations_on_assignee_status_last_activity", order: { last_activity_at: "DESC NULLS LAST" }
      t.index ["assignee_id"], name: "index_conversations_on_assignee_id"
      t.index ["contact_id"], name: "index_conversations_on_contact_id"
      t.index ["contact_inbox_id"], name: "index_conversations_on_contact_inbox_id"
      t.index ["display_id"], name: "index_conversations_on_display_id", unique: true
      t.index ["first_reply_created_at"], name: "index_conversations_on_first_reply_created_at"
      t.index ["inbox_id", "status", "assignee_id"], name: "conv_inbid_stat_asgnid_idx"
      t.index ["inbox_id", "status", "last_activity_at"], name: "index_conversations_on_inbox_status_last_activity", order: { last_activity_at: "DESC NULLS LAST" }
      t.index ["inbox_id"], name: "index_conversations_on_inbox_id"
      t.index ["priority"], name: "index_conversations_on_priority"
      t.index ["status", "last_activity_at"], name: "index_conversations_on_status_last_activity", order: { last_activity_at: "DESC NULLS LAST" }
      t.index ["status", "priority"], name: "index_conversations_on_status_and_priority"
      t.index ["status"], name: "index_conversations_on_status"
      t.index ["team_id"], name: "index_conversations_on_team_id"
      t.index ["uuid"], name: "index_conversations_on_uuid", unique: true
      t.index ["waiting_since"], name: "index_conversations_on_waiting_since"
    end

    create_table "csat_survey_responses", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "conversation_id", null: false
      t.uuid "message_id", null: false
      t.integer "rating", null: false
      t.text "feedback_message"
      t.uuid "contact_id", null: false
      t.uuid "assigned_agent_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["assigned_agent_id"], name: "index_csat_survey_responses_on_assigned_agent_id"
      t.index ["contact_id"], name: "index_csat_survey_responses_on_contact_id"
      t.index ["conversation_id"], name: "index_csat_survey_responses_on_conversation_id"
      t.index ["message_id"], name: "index_csat_survey_responses_on_message_id", unique: true
    end

    unless table_exists?(:custom_attribute_definitions)
      create_table "custom_attribute_definitions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string "attribute_display_name"
        t.string "attribute_key"
        t.integer "attribute_display_type", default: 0
        t.integer "default_value"
        t.integer "attribute_model", default: 0
        t.datetime "created_at", precision: nil, null: false
        t.datetime "updated_at", precision: nil, null: false
        t.text "attribute_description"
        t.jsonb "attribute_values", default: []
        t.string "regex_pattern"
        t.string "regex_cue"
        t.index ["attribute_key", "attribute_model"], name: "attribute_key_model_index", unique: true
      end
    end

    unless table_exists?(:custom_filters)
      create_table "custom_filters", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string "name", null: false
        t.integer "filter_type", default: 0, null: false
        t.jsonb "query", default: "{}", null: false
        t.uuid "user_id", null: false
        t.datetime "created_at", precision: nil, null: false
        t.datetime "updated_at", precision: nil, null: false
        t.index ["user_id"], name: "index_custom_filters_on_user_id"
      end
    end

    create_table "dashboard_apps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "title", null: false
      t.jsonb "content", default: []
      t.uuid "user_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "display_type", default: "conversation"
      t.string "sidebar_menu", default: "conversations"
      t.string "sidebar_position", default: "after"
      t.index ["user_id"], name: "index_dashboard_apps_on_user_id"
    end

    create_table "data_imports", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "data_type", null: false
      t.integer "status", default: 0, null: false
      t.text "processing_errors"
      t.integer "total_records"
      t.integer "processed_records"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "email_templates", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.text "body", null: false
      t.integer "template_type", default: 1
      t.integer "locale", default: 0, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["name"], name: "index_email_templates_on_name", unique: true
    end

    create_table "folders", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "category_id", null: false
      t.string "name"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "inbox_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.uuid "inbox_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["inbox_id", "user_id"], name: "index_inbox_members_on_inbox_id_and_user_id", unique: true
      t.index ["inbox_id"], name: "index_inbox_members_on_inbox_id"
    end

    create_table "inboxes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "channel_id", null: false
      t.string "name", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "channel_type"
      t.boolean "enable_auto_assignment", default: true
      t.boolean "greeting_enabled", default: false
      t.string "greeting_message"
      t.string "email_address"
      t.boolean "working_hours_enabled", default: false
      t.string "out_of_office_message"
      t.string "timezone", default: "UTC"
      t.boolean "enable_email_collect", default: true
      t.boolean "csat_survey_enabled", default: false
      t.boolean "allow_messages_after_resolved", default: true
      t.jsonb "auto_assignment_config", default: {}
      t.boolean "lock_to_single_conversation", default: false, null: false
      t.uuid "portal_id"
      t.jsonb "csat_config", default: {}
      t.integer "sender_name_type", default: 0, null: false
      t.string "business_name"
      t.uuid "account_id"
      t.index ["channel_id", "channel_type"], name: "index_inboxes_on_channel_id_and_channel_type"
      t.index ["portal_id"], name: "index_inboxes_on_portal_id"
    end

    create_table "installation_configs", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.jsonb "serialized_value", default: {}, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "locked", default: true, null: false
      t.index ["name", "created_at"], name: "index_installation_configs_on_name_and_created_at", unique: true
      t.index ["name"], name: "index_installation_configs_on_name", unique: true
    end

    create_table "integrations_hooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.integer "status", default: 1
      t.uuid "inbox_id"
      t.string "app_id"
      t.integer "hook_type", default: 0
      t.string "reference_id"
      t.string "access_token"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "settings", default: {}
    end

    unless table_exists?(:labels)
      create_table "labels", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string "title"
        t.text "description"
        t.string "color", default: "#1f93ff", null: false
        t.boolean "show_on_sidebar"
        t.datetime "created_at", precision: nil, null: false
        t.datetime "updated_at", precision: nil, null: false
        t.uuid "account_id"
        t.index ["title"], name: "index_labels_on_title", unique: true
      end
    end

    create_table "macros", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.integer "visibility", default: 0
      t.uuid "created_by_id"
      t.uuid "updated_by_id"
      t.jsonb "actions", default: {}, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "mentions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.uuid "conversation_id", null: false
      t.datetime "mentioned_at", precision: nil, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["conversation_id"], name: "index_mentions_on_conversation_id"
      t.index ["user_id", "conversation_id"], name: "index_mentions_on_user_id_and_conversation_id", unique: true
      t.index ["user_id"], name: "index_mentions_on_user_id"
    end

    create_table "messages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.text "content"
      t.uuid "inbox_id", null: false
      t.uuid "conversation_id", null: false
      t.integer "message_type", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "private", default: false, null: false
      t.integer "status", default: 0
      t.string "source_id"
      t.integer "content_type", default: 0, null: false
      t.json "content_attributes", default: {}
      t.string "sender_type"
      t.uuid "sender_id"
      t.jsonb "external_source_ids", default: {}
      t.jsonb "additional_attributes", default: {}
      t.text "processed_message_content"
      t.float "sentiment_score", default: 0.0
      t.integer "sentiment", default: 0, null: false
      t.uuid "account_id"
      t.index "content", name: "index_messages_on_content", opclass: :gin_trgm_ops, using: :gin
      t.index ["created_at"], name: "index_messages_on_created_at"
      t.index ["inbox_id", "content_type", "created_at"], name: "index_messages_for_type_date_inbox"
      t.index ["conversation_id"], name: "index_messages_on_conversation_id"
      t.index ["inbox_id"], name: "index_messages_on_inbox_id"
      t.index ["sender_type", "sender_id"], name: "index_messages_on_sender_type_and_sender_id"
      t.index ["source_id"], name: "index_messages_on_source_id"
    end

    create_table "notes", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.text "content", null: false
      t.uuid "contact_id", null: false
      t.uuid "user_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["contact_id"], name: "index_notes_on_contact_id"
      t.index ["user_id"], name: "index_notes_on_user_id"
    end

    create_table "notification_settings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id"
      t.integer "email_flags", default: 0, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "push_flags", default: 0, null: false
      t.index ["user_id"], name: "by_user", unique: true
    end

    create_table "notification_subscriptions", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.integer "subscription_type", null: false
      t.jsonb "subscription_attributes", default: {}, null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.string "identifier"
      t.index ["identifier"], name: "index_notification_subscriptions_on_identifier", unique: true
      t.index ["user_id"], name: "index_notification_subscriptions_on_user_id"
    end

    create_table "notifications", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "user_id", null: false
      t.integer "notification_type", null: false
      t.string "primary_actor_type", null: false
      t.uuid "primary_actor_id", null: false
      t.string "secondary_actor_type"
      t.uuid "secondary_actor_id"
      t.datetime "read_at", precision: nil
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.datetime "snoozed_until"
      t.jsonb "meta", default: {}
      t.datetime "last_activity_at", precision: nil
      t.index ["primary_actor_type", "primary_actor_id"], name: "uniq_primary_actor_per_account_notifications"
      t.index ["secondary_actor_type", "secondary_actor_id"], name: "uniq_secondary_actor_per_account_notifications"
      t.index ["user_id"], name: "index_notifications_on_user_id"
    end

    create_table "platform_app_permissibles", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "platform_app_id", null: false
      t.string "permissible_type", null: false
      t.uuid "permissible_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["permissible_type", "permissible_id"], name: "index_platform_app_permissibles_on_permissibles"
      t.index ["platform_app_id", "permissible_id", "permissible_type"], name: "unique_permissibles_index", unique: true
      t.index ["platform_app_id"], name: "index_platform_app_permissibles_on_platform_app_id"
    end

    create_table "platform_apps", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    # portal_members table removed - functionality replaced by portals_members

    create_table "portals", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.string "slug", null: false
      t.string "custom_domain"
      t.string "color"
      t.string "homepage_link"
      t.string "page_title"
      t.text "header_text"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.jsonb "config", default: {"allowed_locales"=>["en"]}
      t.boolean "archived", default: false
      t.boolean "channel_web_widget", default: false
      t.index ["custom_domain"], name: "index_portals_on_custom_domain", unique: true
      t.index ["slug"], name: "index_portals_on_slug", unique: true
    end

    create_table "portals_members", id: false, force: :cascade do |t|
      t.uuid "portal_id", null: false
      t.uuid "user_id", null: false
      t.index ["portal_id", "user_id"], name: "index_portals_members_on_portal_id_and_user_id", unique: true
      t.index ["portal_id"], name: "index_portals_members_on_portal_id"
      t.index ["user_id"], name: "index_portals_members_on_user_id"
    end

    create_table "related_categories", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "category_id"
      t.uuid "related_category_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["category_id", "related_category_id"], name: "index_related_categories_on_category_id_and_related_category_id", unique: true
      t.index ["related_category_id", "category_id"], name: "index_related_categories_on_related_category_id_and_category_id", unique: true
    end

    create_table "reporting_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.float "value"
      t.uuid "inbox_id"
      t.uuid "user_id"
      t.uuid "conversation_id"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.float "value_in_business_hours"
      t.datetime "event_start_time", precision: nil
      t.datetime "event_end_time", precision: nil
      t.index ["conversation_id"], name: "index_reporting_events_on_conversation_id"
      t.index ["created_at"], name: "index_reporting_events_on_created_at"
      t.index ["inbox_id"], name: "index_reporting_events_on_inbox_id"
      t.index ["name"], name: "index_reporting_events_on_name"
      t.index ["user_id"], name: "index_reporting_events_on_user_id"
    end

    # SLA Events table
    create_table "sla_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "sla_policy_id", null: false
      t.uuid "applied_sla_id", null: false
      t.uuid "conversation_id", null: false
      t.string "event_type", null: false
      t.jsonb "meta", default: {}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["applied_sla_id"], name: "index_sla_events_on_applied_sla_id"
      t.index ["conversation_id"], name: "index_sla_events_on_conversation_id"
      t.index ["event_type"], name: "index_sla_events_on_event_type"
      t.index ["sla_policy_id"], name: "index_sla_events_on_sla_policy_id"
    end

    # SLA Policies table
    create_table "sla_policies", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.text "description"
      t.boolean "first_response_time_enabled", default: false
      t.integer "first_response_time_threshold"
      t.boolean "next_response_time_enabled", default: false
      t.integer "next_response_time_threshold"
      t.boolean "resolution_time_enabled", default: false
      t.integer "resolution_time_threshold"
      t.boolean "only_during_business_hours", default: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
    end

    # Pipelines (replacing campaigns functionality)
    create_table "pipelines", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "created_by_id", null: false
      t.string "name", null: false
      t.text "description"
      t.string "pipeline_type", null: false, default: 'custom'
      t.integer "visibility", default: 0
      t.jsonb "config", default: {}
      t.boolean "is_active", default: true, null: false
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["name"], name: "index_pipelines_on_name", unique: true
      t.index ["created_by_id"], name: "index_pipelines_on_created_by_id"
    end

    create_table "pipeline_stages", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "pipeline_id", null: false
      t.string "name", null: false
      t.integer "position", null: false
      t.string "color", default: '#3B82F6'
      t.integer "stage_type", default: 0
      t.jsonb "automation_rules", default: {}
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["pipeline_id", "position"], name: "index_pipeline_stages_on_pipeline_id_and_position", unique: true
      t.index ["pipeline_id"], name: "index_pipeline_stages_on_pipeline_id"
    end

    create_table "pipeline_conversations", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "pipeline_id", null: false
      t.uuid "conversation_id", null: false
      t.uuid "pipeline_stage_id", null: false
      t.uuid "assigned_by_id", null: true
      t.jsonb "custom_fields", default: {}
      t.datetime "entered_at", default: -> { 'CURRENT_TIMESTAMP' }
      t.datetime "completed_at"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["conversation_id", "pipeline_id"], name: "index_pipeline_conversations_on_conversation_id_and_pipeline_id", unique: true
      t.index ["custom_fields"], name: "index_pipeline_conversations_on_custom_fields", using: :gin
      t.index ["pipeline_id"], name: "index_pipeline_conversations_on_pipeline_id"
      t.index ["pipeline_stage_id"], name: "index_pipeline_conversations_on_pipeline_stage_id"
    end

    create_table "stage_movements", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "pipeline_conversation_id", null: false
      t.uuid "from_stage_id", null: true
      t.uuid "to_stage_id", null: false
      t.uuid "moved_by_id", null: true
      t.integer "movement_type", default: 0
      t.text "notes"
      t.datetime "created_at", null: false
      t.datetime "updated_at", null: false
      t.index ["pipeline_conversation_id"], name: "index_stage_movements_on_pipeline_conversation_id"
    end

    unless table_exists?(:taggings)
      create_table "taggings", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.uuid "tag_id"
        t.string "taggable_type"
        t.uuid "taggable_id"
        t.string "tagger_type"
        t.uuid "tagger_id"
        t.string "context", limit: 128
        t.datetime "created_at", precision: nil
        t.index ["context"], name: "index_taggings_on_context"
        t.index ["tag_id", "taggable_id", "taggable_type", "context", "tagger_id", "tagger_type"], name: "taggings_idx", unique: true
        t.index ["tag_id"], name: "index_taggings_on_tag_id"
        t.index ["taggable_id", "taggable_type", "context"], name: "index_taggings_on_taggable_id_and_taggable_type_and_context"
        t.index ["taggable_id", "taggable_type", "tagger_id", "context"], name: "taggings_idy"
        t.index ["taggable_id"], name: "index_taggings_on_taggable_id"
        t.index ["taggable_type"], name: "index_taggings_on_taggable_type"
        t.index ["tagger_id", "tagger_type"], name: "index_taggings_on_tagger_id_and_tagger_type"
        t.index ["tagger_id"], name: "index_taggings_on_tagger_id"
      end
    end

    unless table_exists?(:tags)
      create_table "tags", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
        t.string "name"
        t.integer "taggings_count", default: 0
        # t.index "lower((name)::text)", name: "tags_name_trgm_idx", using: :gin, opclass: :gin_trgm_ops
        t.index ["name"], name: "index_tags_on_name", unique: true
      end
    end

    create_table "team_members", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "team_id", null: false
      t.uuid "user_id", null: false
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.index ["team_id", "user_id"], name: "index_team_members_on_team_id_and_user_id", unique: true
      t.index ["team_id"], name: "index_team_members_on_team_id"
      t.index ["user_id"], name: "index_team_members_on_user_id"
    end

    create_table "teams", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name", null: false
      t.text "description"
      t.boolean "allow_auto_assign", default: true
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.uuid "account_id"
      t.index ["name"], name: "index_teams_on_name", unique: true
    end

    create_table "telegram_bots", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.string "name"
      t.string "auth_key"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
    end

    create_table "webhooks", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "inbox_id"
      t.string "url"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.integer "webhook_type", default: 0
      t.jsonb "subscriptions", default: ["conversation_status_changed", "conversation_updated", "conversation_created", "contact_created", "contact_updated", "message_created", "message_updated", "webwidget_triggered"]
      t.string "name"
      t.index ["url"], name: "index_webhooks_on_url", unique: true
    end

    create_table "working_hours", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
      t.uuid "inbox_id"
      t.integer "day_of_week", null: false
      t.boolean "closed_all_day", default: false
      t.integer "open_hour"
      t.integer "open_minutes"
      t.integer "close_hour"
      t.integer "close_minutes"
      t.datetime "created_at", precision: nil, null: false
      t.datetime "updated_at", precision: nil, null: false
      t.boolean "open_all_day", default: false
      t.index ["inbox_id"], name: "index_working_hours_on_inbox_id"
    end

    # Foreign Keys
    add_foreign_key "inboxes", "portals"

    add_foreign_key "pipeline_conversations", "pipelines"
    add_foreign_key "pipeline_conversations", "conversations"
    add_foreign_key "pipeline_conversations", "pipeline_stages"

    add_foreign_key "stage_movements", "pipeline_conversations"
    add_foreign_key "stage_movements", "pipeline_stages", column: "from_stage_id"
    add_foreign_key "stage_movements", "pipeline_stages", column: "to_stage_id"
    # Database Triggers and Sequences - Removed, using Rails callback instead
  end

  def down
    raise ActiveRecord::IrreversibleMigration, "The initial migration is not revertable"
  end
end
