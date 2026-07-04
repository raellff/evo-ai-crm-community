# Changelog

All notable changes to **evo-ai-crm-community** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **EVO-1239** — Wisper `:message_status_changed` agora é emitido por todos os providers WhatsApp (Cloud, 360-dialog, Evolution API, Evolution Go single/bulk, Baileys), Telegram (delivered + failed) e Email/SMTP (delivered + bounce DSN). Inclui novo `BounceMailbox` parseando DSN RFC 3464 (Status `5.x.x` → failed; `4.x.x` apenas logado).

### Changed

- **EVO-1239** — Telegram `send_on_telegram` passa a registrar status `delivered` após envio bem-sucedido. Read receipts não são suportados pela Bot API (Telegram limitation) e portanto `read` permanece n/a neste canal.

## [v1.0.0-rc6] - 2026-07-04

A large feature release built around four themes: **(1) global Message Templates cutover** (dedicated CRUD, data migration of legacy channel-coupled templates, shared variable resolver), **(2) a new SendGrid email channel**, **(3) storage/media overhaul** (ActiveStorage now defaults to `:local`, attachments served through the app proxy), and **(4) server-side PII masking for non-admin users**. It also ships the B14 Lead Capture surface (form-builder + chat pages), conversation-history and product CSV imports, a round of automation-engine repairs, pipeline performance work, label-tagging persistence fixes, WhatsApp channel-state hardening, and a significantly more capable Evolution Hub integration (IG/FB DMs, auto-healing, template re-sync).

### Highlights

- **Message Templates go global** — templates are decoupled from channels (EVO-1231), get a dedicated CRUD endpoint with inbox cutover (EVO-1716), a data migration that moves legacy channel-coupled templates into the global flow (EVO-1234, hardened in EVO-1718/1719), WhatsApp Cloud approval sync (EVO-1232), and a shared variable resolver used by journey and API sends (EVO-1267).
- **SendGrid email channel** — full channel implementation: model + CRUD (EVO-1248), API-key validation with event-webhook registration (EVO-1249), event webhook receiver (EVO-1250), `mail/send` client with per-message wire-up (EVO-1251), and HTML template rendering (EVO-1721).
- **Storage defaults changed (breaking for S3 installs)** — `ACTIVE_STORAGE_SERVICE` now defaults to `local` instead of `s3_compatible`, with an automatic fallback to `:local` when the configured bucket is missing (EVO-1961). Attachments are served through the app proxy by default via the new `ATTACHMENT_DELIVERY` flag (EVO-2006), and `ACTIVE_STORAGE_URL` is honored across browser, Sidekiq and previews (EVO-1747).
- **Server-side PII masking** — contact phone/email/identifier are masked for non-admin users across REST, ActionCable broadcasts and background jobs (EVO-1551, three hardening rounds).

### Added

- **Message Templates — global cutover (EVO-1231/1232/1234/1235/1716/1717)** — templates decoupled from channels for a global menu, channel link + WhatsApp Cloud approval sync, migration of channel-coupled templates into the global flow, message-send call sites rewired to the global `MessageTemplate`, dedicated CRUD endpoint with inbox cutover, and WABA-wide template status lookup. Service-token reads allowed on per-inbox templates (EVO-1255), and a global template can now be used as an inbox greeting / out-of-office message (EVO-1760).
- **Shared template variable resolver (EVO-1267)** — one resolver for journey and API sends, replacing per-call-site interpolation.
- **SendGrid email channel (EVO-1248/1249/1250/1251)** — channel model, migration and CRUD; key validation and automatic event-webhook registration on channel save; event webhook receiver (delivery/bounce/suppression tracking on contacts); `mail/send` client wired per message, with email signature support.
- **B14 CRM Lead Capture (EVO-1771)** — form-builder (`crm_forms`) and public chat pages (`chat_pages`) for capturing leads into the CRM.
- **Conversations history import (EVO-1557)** — import past conversations via `DataImport`.
- **Products CSV bulk import (EVO-1555)** — bulk import endpoint, plus a `dry_run` preview mode with per-row validation and response counts (EVO-1736); products endpoints now return structured field errors (EVO-1783).
- **Pipeline stage inactivity actions** — configurable actions fired when an item sits in a stage past a threshold, with scheduling and execution tracking (`stage_inactivity_executions`).
- **`update_custom_attribute` automation action (EVO-1751)**.
- **RBAC — per-inbox granularity** — agents' conversation access is scoped by role via `assigned_inboxes`; orphaned `team_members` links are healed.
- **Evolution Hub expansion** — Instagram/Facebook DMs received via the Hub now become conversations (dispatch shape + activation on `channel_connected`); `ChannelReconciler` + `EvolutionHubReconcilable` concern auto-heal broken channels; Cloud API templates are re-synced after `channel_connected` (EVO-1827); IG contact profile (name/photo) enriched via Hub proxy; new `HUB_ALLOW_EXISTING_CHANNELS` flag to disable "use existing channel" linking.
- **Live channel state on `/inboxes` (EVO-1674)** — exposes `connection_state` / `last_sync`.
- **Segments proxy (EVO-1247/1569)** — segments CRUD + preview, delete/recompute/contact-ids proxied through the CRM.
- **evo-flow journey support** — `pipeline.stage_changed` published to evo-flow (EVO-1266), `move_conversation` endpoint (EVO-1272), `pipeline_tasks#for_conversation` (EVO-1273), `email_team` and `canned_response` show endpoints (EVO-1634), unread conversation count endpoint (EVO-1550).
- **Timeline activity for handoffs** — AI→human handoff persisted as an activity message (EVO-1560) and reverse human→bot handoff recorded (EVO-1680).
- **Canned response attachments (EVO-1861)** — read, remove, size limit.
- **WhatsApp contact-revoke notice + agent-delete propagation (EVO-1890/1891)**.
- **Contacts — filter by company (EVO-1887)** via the `contact_companies` association; label `usage_count` exposed with tagging cleanup on delete (EVO-1863).
- **Inbox member notifications (EVO-1459)** — members notified on new messages in unassigned conversations.
- **ERP webhook ingress (EVO-1735 S3.0)** — infra-only receiver groundwork.
- **CI — per-PR images (EVO-1998)** — every internal PR builds `:pr-N` (+ `:sha`) images for the review environment.

### Changed

- **`ACTIVE_STORAGE_SERVICE` default is now `local` (EVO-1961)** — previously `s3_compatible`. When an S3-compatible service is configured but the bucket is missing/misconfigured, boot falls back to `:local` (checking the correct bucket key per provider) instead of crashing. **Breaking for S3 installations**: set `ACTIVE_STORAGE_SERVICE=s3_compatible` explicitly (see upgrade notes).
- **Attachment delivery via app proxy (EVO-2006)** — new `ATTACHMENT_DELIVERY` env (default `proxy`) serves inbound and outbound media through ActiveStorage's proxy instead of redirecting to storage URLs; fixes broken media on S3/MinIO installs behind private buckets.
- **`ACTIVE_STORAGE_URL` honored everywhere (EVO-1747)** — browser-facing URLs, Sidekiq jobs and previews all use the configured public URL.
- **`file` mediatype mapped to `document` for Evolution API media send (EVO-1940)**.
- **Automation engine — Ruby contact-condition evaluator retired (EVO-1642)** — phase 1 introduced a contact-capable conditions filter with shadow-compare; phase 2 removed the legacy Ruby evaluator.
- **Model enums migrated to positional syntax for Rails 7.1+ (EVO-2007)**, with a boot-safe `source` enum via explicit attribute.
- **Pipelines list served without items** — stages count only, plus contact-labels skipped in the pipelines payload to kill N+1s; `days_in_current_stage` and task counts optimized.
- **Phone number normalization** — comprehensive normalization for contacts (also applied to WhatsApp echo handling).
- **PgBouncer settings adjusted** for prepared statements and advisory locks.

### Fixed

#### Automation engine
- **EVO-1635** — contact-triggered automations now execute and are recorded.
- **EVO-1638** — contact condition operators and labels semantics corrected.
- **EVO-1640** — silent contact drops now recorded as skipped runs.
- **EVO-1641** — flow-mode action execution unified with simple mode.

#### Pipelines
- **EVO-1845** — idempotent heal for `stage_movements.pipeline_item_id` drift (data-heal migration).
- Pipeline stats and funnel list now include **value**, not just counts.
- Existing contact pipeline prioritized when creating a conversation; conversation merged into the contact's lead card (with a revert/refix cycle to avoid duplicate cards).
- **EVO-1915** — `pipeline_items` notes persist without a stage and the response reflects the actual write.

#### Labels
- **EVO-1897** — tagging persisted on `contacts/labels#create`.
- **EVO-1928** — contact tagging by name persisted.
- **EVO-1932** — `Labelable` write paths hardened to always persist taggings.
- **EVO-1863 (review)** — `label.removed` emitted for conversations on label delete; labels GET/POST render JSON (a 204 was wiping tags client-side).

#### WhatsApp / channels
- **EVO-1967** — channel no longer stuck in `reauthorization` after a transitory close.
- **EVO-1748** — WhatsApp revoke/protocol messages skipped on `evolution_go` inbound.
- **EVO-1682** — contact identifier format validated before use as WhatsApp destination.
- Echo message handling normalizes phone numbers and ensures contact creation.
- Hub `channel_token` retrieval and persistence hardened; IG/FB profile-fetch failure (error 190) no longer wedges the channel.

#### API / conversations
- **EVO-1898** — `status_explicitly_set!` call fixed in `ConversationBuilder`.
- **EVO-1899** — `error_response` keyword→positional fixed across all call sites; **EVO-1923** — missing `ApiErrorCodes` constants defined.
- **EVO-1900** — `agent_bot_inbox` persisted in `set_agent_bot`.
- **EVO-1914** — invalid assignee/team id rejected without clearing the current assignment.
- **EVO-1972** — `conversations#show` no longer serializes the full message thread.
- **EVO-1958** — `inbox.agent_bot_inbox` preloaded on the conversation list (N+1).
- **EVO-1960** — conversation-list backend: sort parity, chips, archived.
- **EVO-1849/1850** — contact `country_code` filter on the top-level column; `custom_attributes` display-name keys backfilled to `attribute_key`.

#### EvoFlow
- **EVO-1570** — required `source` emitted in backfill payloads; **EVO-1571** — proxy reads events from the `data.events` envelope.

#### Misc
- **EVO-1966** — dev stack no longer corrupts `db/schema.rb` (schema dump disabled after migration).
- Agent `contextId` stabilized (indifferent-access payload); agent media links rendered as real media; `ZapiSyncListener` only reads `provider` on WhatsApp channels.
- SendGrid sends render the template HTML instead of raw `message.content` (EVO-1721).

### Security

- **EVO-1551 — server-side PII masking for non-admin users** — contact `phone`/`email`/`identifier` (and phone-like names) are masked for agents when the account flag is on, across REST serializers, ActionCable broadcasts and background jobs. Three hardening rounds closed leaks in listener paths without `Current.user`, account-wide broadcasts triggered by admins, `ContactInbox#source_id` (WhatsApp JIDs embed the phone), notification sender names, pre-chat `content_attributes`, and `contactable_inboxes` (default-deny with an opaque-id allowlist; the builder regenerates `source_id` server-side).
- **EVO-1938 — Segments proxy endpoints now enforce permissions**, alongside per-inbox RBAC scoping.
- **`EVOLUTION_HUB_API_KEY` encrypted at rest and masked in API responses** (migration `encrypt_evolution_hub_api_key_at_rest`).
- **`HUB_ALLOW_EXISTING_CHANNELS`** — flag to disable linking existing Hub channels, preventing cross-tenant channel leakage.
- **Server-to-server permission checks use the service token**, not the user bearer.
- **OAuth `config_types` allowlist** for MCP integrations in the admin.
- **CI — `build-pr` gated to internal PRs** (forks get no secrets).

### Notes for upgrade

- **Run `db:migrate`** — 15 new migrations (`20260608194533` … `20260701120000`): SendGrid channel tables, message-template decoupling + legacy refs, stage inactivity executions, CRM forms + chat pages, `stage_movements` FK heal, `source` columns on messages/conversations, contact custom-attribute key backfill, and at-rest encryption of `EVOLUTION_HUB_API_KEY`. The template data migration moves legacy channel-coupled templates into the global flow and is idempotent (same-named legacy templates preserved).
- **Breaking — storage default changed**: `ACTIVE_STORAGE_SERVICE` now defaults to `local` (was `s3_compatible`). Installations using S3/MinIO **must set `ACTIVE_STORAGE_SERVICE=s3_compatible` explicitly** or attachments will be written to local disk after upgrade.
- **New/changed environment variables**: `ATTACHMENT_DELIVERY` (default `proxy`; set `redirect` to restore direct storage URLs), `ACTIVE_STORAGE_URL` (public base URL for attachment links in browser/Sidekiq/previews), `HUB_ALLOW_EXISTING_CHANNELS` (default on; set to disable existing-channel linking).
- The PII masking of EVO-1551 is controlled by an account flag; behavior is unchanged until the flag is enabled.

## [v1.0.0-rc5] - 2026-05-27

Hardening of fresh-install plus a substantial expansion of the EvoFlow surface. Critical first-boot fixes (auth-service race on first start, EvoFlow event schema sanity) ship alongside new EvoFlow capability: a `contact_events` backfill worker, the proxied `/contacts/:id/events` endpoint with enrich, five new flow node types wired into automation rules, and Evolution Hub promoted into a usable Meta proxy (channel linking, legacy gate removed).

### Highlights

- **Fresh-install hardening** — first-boot races and missing schema entries that affected clean installations are resolved; new deployments now come up cleanly without manual intervention.
- **EvoFlow expansion** — `contact_events` backfill worker, proxied events endpoint with enrich (EVO-1243), five new flow node types in `ActionService` (EVO-1262), and Ruby-side event schema mirror with validator (EVO-1261).
- **Evolution Hub usable as a Meta proxy** — inboxes can now be linked to an existing Hub channel and the legacy `EVOLUTION_HUB_URL` gate is gone.

### Added

- **EVO-1243 — Proxied `/contacts/:id/events` endpoint with enrich** — exposes a contact's event stream from EvoFlow through the CRM, enriching each event with the additional context the UI needs. Includes a STI guard added during review hardening.
- **EVO-1261 — Ruby-side mirror of the EvoFlow event schema + `SchemaValidator`** — `EVENT_SCHEMA` is mirrored in Ruby and deep-frozen; the validator enforces strict UUID format, rejects empty strings, performs an eager schema check, and raises on unregistered event names. Backed by review iterations covering the cast of `inbox_id` / `assigned_by_id` to `:uuid` in the fork.
- **EVO-1262 — Five new flow node types in automation rules** — `ActionService` is collapsed onto shared pipeline and message action handlers, and five new flow node types are wired through them. Ships with a parity harness, spec coverage, and a README describing the shared-handler contract.
- **EvoFlow `contact_events` backfill worker** — backfills the new `contact_events` data set for installations that predate EvoFlow. Hardened across two review passes.
- **Evolution Hub — link inbox to an existing Hub channel** — operators can now attach a CRM inbox to a pre-existing Evolution Hub channel rather than always provisioning a fresh one through the proxy.
- **Notifications payload — sender name, avatar, preview and `last_activity_at`** — the notification payload now carries enough context for clients to render a rich list without an extra round-trip.

### Changed

- **EVO-1419 — Notifications scope tightened** — inbox fan-out is no longer part of the EVO-1419 scope; the payload-enrichment work above is the remaining deliverable. `pipeline_task_*` notification types are declared explicitly out of scope for this iteration.
- **WhatsApp Cloud send errors routed through `StatusUpdateService`** — send-time errors on WhatsApp Cloud now flow through the same status-update funnel as the other providers, keeping the message-status pipeline consistent.
- **Schema regenerated for `AddEvolutionHubMetaToChannels` (EVO-1455)** — `schema.rb` reflects the new Evolution Hub Meta columns on `channels`.

### Fixed

- **EvoFlow — missing schema entries for 5 conversation events** — closes gaps in the freshly mirrored event schema that surfaced during fresh-install smoke tests.
- **Evolution Hub — legacy `EVOLUTION_HUB_URL` gate removed** — installations no longer need to set the legacy environment variable for Hub flows to activate; configuration is read from the canonical source.
- **Notifications — nil sender on assignment + `avatar_url` lookup** — assignment notifications no longer crash when the assigning user is nil, and `avatar_url` is fetched defensively.

### Notes for upgrade

- Run `db:migrate` on upgrade — the `AddEvolutionHubMetaToChannels` migration adds the Evolution Hub Meta columns to `channels`.
- Fresh installs now boot cleanly when the auth service races with other services on first start; no manual workaround is required on new deployments.
- The EvoFlow `contact_events` backfill worker is safe to run on existing installations and is idempotent. Operators upgrading from rc4 should let it complete before relying on the new `/contacts/:id/events` endpoint.
- No new required environment variables. `EVOLUTION_HUB_URL` is no longer consulted; if you still have it set, you can remove it.

## [v1.0.0-rc4] - 2026-05-25

Two main themes drive this release: **(1) Evolution Hub** integration as an optional proxy for Meta channels (proxy inbox creation, webhook receiver, cleanup with remote webhook deletion), and **(2) groundwork for upcoming features** not yet exposed to end users, including an internal events module foundation and listener port. Also rolls up fixes for legacy single-account assumptions, interactive-message hardening, macro execution status persistence, and Typebot interactive-button rendering.

### Added

- **Evolution Hub as an optional proxy for Meta channels** (tasks 10-18, 19-24) — wires Evolution Hub as an optional path for Meta channels (WhatsApp/Instagram/Facebook). Includes a dedicated webhook receiver, an `InboxBuilder` that creates proxy inboxes via the Hub, `hub_pending?` / `hub_active?` lifecycle on the `Channel` model, hardened validation, and cleanup that now propagates webhook deletion to the remote Hub. The feature is opt-in: when Evolution Hub is not configured, the direct Meta flow continues to work as before.
- **EVO-1088 — Macro execution status persistence + webhook failure surfacing** — macro executions now persist status (success/failure/error message) and expose failures via the webhook payload so external automations can react. Paired with the matching frontend change (real execution result in the UI).
- **Typebot interactive buttons in the agent-bot** — Typebot `choice` blocks render as interactive buttons. Paired with `evo-ai-processor-community` (#12) and `evo-ai-frontend-community`.
- **Groundwork for an internal events module** — foundation for a future CRM events module (client + payload + worker + listeners covering contact/conversation/message/pipeline). **Not user-facing in this release** — preparation for an upcoming feature, with no menu entry and no documented route.

### Changed

- **Legacy schema cleanup** — removes deprecated tables tied to features that are not yet GA in the release-candidate stream. Idempotent migration. **No impact on production data** (the dropped tables were not in use).
- **Strengthened label/conversation listeners** — F-2 of `label_list` now emits via a consistent setter, covering mutation paths that previously did not fire events. Includes specs for service paths, M1 integration, and M2 rollback.

### Fixed

- **EVO-1372 — Interactive message hardening** — payload validation, truncation of long text to Meta/WhatsApp limits, and edge-case handling (empty lists, duplicate options).
- **Legacy single-account assumptions** — internal CRM paths still dereferenced an `Account` model that was removed in earlier release-candidates. The remaining call sites have been fixed.
- **Evolution Hub — proxy inbox creation flow unblocked** — bug that prevented inboxes from being created via the Hub proxy even when configuration was valid.
- **Dead `previous_changes` branch in an event listener** — removed and documented (commit-level cleanup).
- **Internal events module hardening** — multiple post-merge review iterations on the events module (not GA), including AC closures, review follow-ups, and freezing `EVENT_NAMES` (raises `InvalidEventName` for unregistered strings).

### Upgrade notes

- This release includes a legacy schema cleanup migration. Run `db:migrate` on upgrade. **No production data is affected** — the removed tables were not in use.
- The internal events module groundwork is dormant in this release. No new environment variables, no endpoints exposed to end users. Operators only need to run `db:migrate`.

## [v1.0.0-rc3] - 2026-05-17

Stabilization release — focuses on bug fixes for payload parity with Evolution Go (buttons/lists), outbound media delivery, Notificame verify endpoint hardening, secret filtering in Rails logs, bulk actions, IDOR scope, and several automation rules fixes. Also consolidates the open-core foundation via `EXTENSION_POINTS.md` + `lib/evo_extension_points/` (no-op modules), introduces a products catalog with variants + pipeline-integrated sales, template bundle export/import (EVO-1116), and an endpoint to clear admin configuration by type.

### Added

- **Products catalog** — full products model with variants, attach to agents via a dedicated tab, and sales integrated into the pipeline (sales panel on the pipeline item).
- **Template Bundles — export & import (EVO-1116)** — configuration export and import via ZIP bundle. Lets you package inboxes, agents, automation rules, canned responses, and templates into a single file portable across installations.
- **EVO-1051 — `DELETE` endpoint to clear admin config by type** — the installation operator can reset specific configurations (SMTP, Storage, etc.) without having to edit the database.
- **EVO-1287 — CI guard-rail for the `EvoExtensionPoints` contract** (#76) — workflow that fails the PR if modules under `lib/evo_extension_points/` are modified without intentional review. Ensures the Enterprise edition can keep injecting implementations without needing a fork.
- **EVO-1286 — `lib/evo_extension_points/` with 5 no-op modules** (#75) — extension points declared as no-op modules, ready to be reopened by Enterprise. Contract versioned in `EXTENSION_POINTS.md`.
- **EVO-1283 — `EXTENSION_POINTS.md`** (#73) — document declaring 4 versioned hooks exposed by the CRM as a public extension contract.
- **EVO-1058** — `attribute_changed` operator on labels with dispatch dedup (#56). Automation rules now react to label assignment changes without firing twice for the same event.
- **EVO-1057** — listeners for `conversation_resolved` and `conversation_status_changed` (#53). Expands the automation rules trigger vocabulary to cover conversation status changes.
- **EVO-1011 — Bulk actions** — per-item result collection and response with `success_ids` / `failed_ids`, support for bulk-resolving conversations via checkbox.
- **Pipelines — `move_to_pipeline` action** — automation rules gain an action to move a conversation between pipelines while preserving the item id. Includes `pipeline_stage_updated` dedup in a 5s window per `(rule, pipeline_item, stage)` to avoid event storms.
- **Inboxes — variable expansion in message templates** — variables gain additional fields (`label`, `source`, `example`, `position`, `component`) accessible inside the template.
- **Automation rule runs — management + cleanup job** — API endpoint to query rule execution history + periodic cleanup job.
- **Action service** — new `send_canned_response` and `send_template` methods on `ActionService` (direct use by automations).
- **Regression spec** — `pipeline_item_spec` for the auto-assign-and-move flow (EVO-1080) (#57).
- **Regression spec** — Notificame verify endpoint (EVO-986).
- **Regression spec** — contact deletion with attachments (EVO-973) (#46).
- **Contract spec** — `Webhooks::Trigger` and hardening of the macros spec (EVO-1041).

### Changed

- **EVO-1113 — Credential resolution consolidated into `EvolutionConcern`** — previously the logic was spread across providers; now a single concern centralizes the per-field fallback for `api_url`, `admin_token`, and other Evolution credentials. Reduces bug surface and makes switching between Evolution API and Evolution Go easier.
- **Docs** standardized for Evolution Foundation 2026 (README, LICENSE, NOTICE, TRADEMARKS).
- **Docs (org)** — GitHub URLs updated from `EvolutionAPI` to `evolution-foundation`.
- **Schema** — comments updated on `automation_rule_run`, `role`, and `user_role`.
- **Schema** — removed unused tables and foreign keys.

### Fixed

#### Messaging — Evolution Go / Evolution API
- **EVO-1115 — buttons/lists payload for Evolution Go** (#72) — format fixed for parity with Evolution Go. Interactive messages (buttons and lists) were arriving malformed; they now follow the schema expected by both providers.
- **EVO-1151 — outbound media delivery failure** (#70) — fixed for Evolution API and Evolution Go. Outgoing attachments were not reaching the recipient in certain size/codec scenarios.
- **Duplicate messages in the Evolution Go incoming handler** — handler now deduplicates events before creating the conversation.
- **Evolution configuration fallback** — `api_url` and `admin_token` now fall back to `GlobalConfig` when per-inbox configuration is empty.

#### Notificame / Webhooks
- **EVO-986 — Notificame verify endpoint hardening** — mandatory auth, payload validation, no error leakage. The previous endpoint exposed error details useful for enumeration.
- **EVO-1041 — Macro webhook delivery failures** — macro webhook failures are now surfaced (previously they were silent). The re-raise is restricted to `:macro_webhook` to avoid retry storms on other types. Correctly wired through `ExecutionService` → `WebhookJob`.

#### Automation rules
- **EVO-1130 — Notificame attachment fallback_title** (#69) — prefers `content[:fileName]` when available to generate the attachment title.
- **EVO-1049 — BMS/Resend delivery method** (#66) — fixed delivery method symbol resolution to the correct class.
- **EVO-1011 — Bulk actions** — fixes for HIGH review findings (rounds 2 and 3), fixture spec with valid `pipeline_type` (EVO-1047).
- **`labels` condition** — now uses an `EXISTS` subquery (independent and NULL-safe), resolves UUIDs to titles with fallback, and matches a label on conversation OR contact.
- **`message_type` filter** — accepts numeric values, not just enum keys.
- **`apply_label` action** — resolves UUIDs to titles before tagging.
- **`pipeline_stage_updated`** — 5s window dedup per `(rule, pipeline_item, stage)` prevents burst firing.
- **Cross-pipeline stage movement** — correct bypass of the `same-pipeline` validation when the action is `move_to_pipeline`.
- **Action templates** — `send_template` uses `deep_stringify_keys`, improved parameters.
- **`MessageTemplateVariable`** — defined locally to avoid breaking the build.
- **Diagnostic logging** — added in `move_to_pipeline` and `pipeline_stage_updated` for investigating production issues.

#### Contacts / Pipeline
- **EVO-1018 — Group contacts** — distinguishes WhatsApp group contacts from real customer contacts; review feedback applied.

#### Media (EVO-999)
- **HIGH review findings** applied to the media fixes: `video file_type` fallback, `fallback_title` on attachments, all download paths covered.

#### Stability
- **Docker — bundler version** — pinned during installation to avoid non-deterministic builds.
- **EVO-1047** — `pipeline_item_spec` uses a valid `pipeline_type` in the fixture (previously broke the spec).

### Security

- **EVO-1111 — Secret filtering in Rails logs** — sensitive fields (`password`, `token`, `api_key`, etc.) go through Rails filter parameters before reaching the log. Previously it was possible to leak credentials in error/debug logs.
- **EVO-1084 — IDOR scope in `BulkActionsJob`** — account scope applied in the job; previously, with a valid ID from another account, it was possible to manipulate cross-tenant resources.
- **EVO-986 — Notificame verify endpoint** — mandatory auth + closed validation + no error leakage (see Fixed).

## [v1.0.0-rc2] - 2026-05-05

Stabilization release — focuses on `500 Internal Server Error` fixes on REST endpoints, Evolution Go flow fixes, per-stage automation rules, card → conversation navigation, pipeline performance, idempotent migrations for deploys on drifted schemas, `super_admin` RBAC recognized as administrator across all bypasses, and S3 signed URLs for private buckets on both WhatsApp providers.

### Added

- **EVO-989** — **Per-stage automation rules**: new feature that lets you configure `trigger → action` rules per pipeline stage. Supported triggers: `label_added`, `conversation_status_changed`, `custom_attribute_updated`. Actions: `move_to_stage`, `assign_agent`, `apply_label`. Async execution via Sidekiq with loop prevention (`Current.executed_by = :stage_automation`). Includes `Pipelines::StageAutomationService`, `PipelineStageAutomationListener`, and whitelist payload validation in the controller. (#44)
- **EVO-1007 backend** — `PipelineItemSerializer` now exposes `conversation.uuid` in the pipeline payload so the frontend can navigate directly from the card to `/conversations/<uuid>`. Scoped change (does not touch the global `ConversationSerializer`) to avoid regressions in chat. (#43)
- **EVO-1006** — search and filters added to the pipeline kanban (backend portion was already in rc1, finalized with `include_labels` along the serialization chain — #39).
- **EVO-987** — inline label creation from the "Assign Label" modal (backend support).

### Fixed

#### REST API — bugs causing 500
- **`PATCH /api/v1/pipelines/:id/pipeline_items/:id/update_custom_fields`**: `before_action :set_pipeline_item` did not cover `:update_custom_fields`, so `@pipeline_item` was `nil` and every call raised `NoMethodError`. (#32)
- **`POST /api/v1/contacts/:id/companies` raised `NoMethodError`**: `validate :must_belong_to_same_account` declared on `ContactCompany` had no implementation. Defined as `no-op` (Community is single-tenant). (#34)
- **`POST` / `DELETE /api/v1/contacts/:id/companies` returned 500 on business rule violation**: `error_response(code:, message:)` was called with kwargs incompatible with the helper signature (positional). Fixed to return 400 with a `BUSINESS_RULE_VIOLATION` envelope. (#35)
- **`/api/v1/agents/*` returned 500 / `Unauthorized`**: `current_user` was being passed as the first positional argument to `EvoAiCoreService.*_agent` (the signature expects `params` / `agent_data` / `agent_id`); additionally, `request.headers` was never forwarded, so `evo-core` received calls without a Bearer token. (#33) — *follow-up tracked in [#42](https://github.com/EvolutionAPI/evo-ai-crm-community/issues/42) to replicate the fix in the remaining controllers (`apikeys`, `folders`, etc).*
- **`GET /api/v1/oauth/applications`**: returned a raw JSON array, but the frontend expects the standard envelope `{ success, data, meta: { pagination } }`. The `/settings/integrations/oauth-apps` screen broke with `TypeError: Cannot read properties of undefined (reading 'pagination')`. (#36)
- **EVO-1000** — `POST /api/v1/team_members` returned 401 + body `{"error":"Invalid User IDs"}` for every valid UUID (the validation did `params[:user_ids].map(&:to_i)`, but `User`'s PK is a UUID — all of them became `0` and never matched). Rescue adjusted to `RecordInvalid` / `InvalidForeignKey` with a clean 422. (#24)

#### Evolution Go (EvoGo) — WhatsApp flow
- **Conversation routing — no more duplicate conversations**: when the CRM sent a message via EvoGo, the echo came back as a webhook with `IsFromMe: true`, but contact lookup was by phone number — outgoing uses LID identifier (`@lid`), so no match was found and a new conversation was created on every send. Lookup now prioritizes LID identifier and falls back to phone. (#22)
- **Correct sender type and contact lookup**: outgoing messages were being saved as `sender_type: Contact` instead of `User`. The inbox join in the contact lookup was also wrong. Fixed + reopening of pending conversations when a new message arrives. (#22)
- **Media (image / audio / video) saved without file**: 3 distinct problems fixed together: (1) `ActiveStorage#after_commit` did not fire under Sidekiq → migrated to synchronous `ActiveStorage::Blob.create_and_upload!`; (2) `mediaUrl` nested inside `imageMessage`/`audioMessage`/etc. is now extracted via `extract_media_url`; (3) EvoGo without S3 sends media as inline `base64` — added decode to `Tempfile`. (#22)
- **Audio without waveform / duration / PTT**: `configure_audio_metadata` and `audio_voice_note?` were **defined twice** in the same module (Ruby silently used the last definition, which was an incomplete stub with the wrong keys). Merged into single definitions using symbol keys. Also removed `save_message_and_notify` and `attach_media_from_url` which were dead code. (#22)
- **ActionCable — broadcast to empty token**: `account_token` returned `""` (empty string) when account was nil, and `[account_token].compact` let the empty string through, causing a broadcast to an empty channel. The function now returns `nil` (a real nil) and accepts both Hash and AR-object as input. `ActionCableBroadcastJob` also became tolerant of payloads with string or symbol keys. (#22)
- **Media in private S3 bucket returned 404 in chat**: `generate_direct_s3_url` built the public URL directly (`bucket.host/key`), but installations using Cloudflare R2 or S3 with private ACL block public access. Replaced with `presigned_url` (signed URL with short expiration) both in `whatsapp/providers/evolution_go_service.rb` (commit `316849d`) and in `whatsapp/providers/evolution_service.rb` (commit `daa9ee9` — the traditional Evolution API path was fixed afterwards with the same logic).

#### Listeners and dispatchers
- **`ContactCompanyListener`**: events were being published via `Wisper::Publisher` with `data: { ... }`, but every listener in the project reads them as `event.data[:contact]` (expecting the `Events::Base` wrapper from `SyncDispatcher`). Result: `undefined method 'data' for an instance of Hash` in the log + `CONTACT_COMPANY_LINKED` broadcast never fired. Migrated to `Rails.configuration.dispatcher.dispatch(...)` in `LinkCompanyService`, `UnlinkCompanyService`, `Contact#add_company`, and `#remove_company`; listener tolerates `account: nil` via `single_tenant_account`. (#37)
- **EVO-975** — `assign_to_default_pipeline` on conversation creation: removed `:account` from the eager loading in `pipelines_controller#fetch_pipeline` (the association does not exist in the community edition and was raising `AssociationNotFoundError`, preventing `is_default: true` from being persisted), and added detailed logging to diagnose future issues. (#26)

#### Performance and lists
- **Pipeline chip in the conversation list only appeared after tagging**: `ConversationFinder#build_conversations_query` intentionally kept the preload minimal, without `pipeline_items`. Since `ConversationSerializer` only populates the `pipelines` block when the association is loaded, the frontend received `pipelines: []` and `ConversationBadges` fell into the "no pipeline" branch. Added `pipeline_items: [:pipeline, :pipeline_stage]` to the preload — the chip now renders from the first load.

#### Serializers
- **EVO-1010** — `TeamSerializer` now includes `members_count` (running `team.team_members.count` indexed by `team_id`), fixing cards / rows that showed `0 members` even with members associated. (#25)

#### RBAC — `super_admin` recognized as administrator
When `evo-auth-service-community` introduced the `super_admin` role (see the auth changelog in this same release), the CRM's hardcoded lists still pointed only to `account_owner`, so the installation operator appeared to have no privileges in several subtle bypasses (admin mailers, admin finders, permission helpers).
- **`User#administrator?`**: now accepts both `account_owner` and `super_admin` (`app/models/concerns/user_attribute_helpers.rb`). Previously, filters like `Conversation.assignable_by` returned empty for super_admin, and the conversation list appeared empty even with a valid JWT.
- **`Role::ADMIN_ROLE_KEYS`**: new constant centralizing `%w[account_owner super_admin]`. Adopted by `AdministratorNotifications::BaseMailer#admin_emails` (installation notifications) and by every finder/scope that filtered by admin role.
- **Effect**: no endpoint needed to be changed individually — the constant consolidated what was spread across four places (commit `5f1eed2`).

#### Pipelines / Templates / Messaging (from the `develop` cycle)
- **EVO-974**: accepts a payload with nested filters, supports `pipeline_id` / `contact_id`, and `query_builder` now pairs `row + clause` to survive empty clauses.
- **EVO-1002**: `MessageTemplate#serialized` mirrors `settings.status` at the top level; template creation routes through the sync provider (Meta) and no longer flips `active` to `false` when syncing `PENDING` / `REJECTED` templates.
- **EVO-1001**: resolves label UUIDs when tagging / rendering conversations. (#14)
- **EVO-1005**: `pipeline_items#update` persists `pipeline_stage_id`. (#27)
- **EVO-1006**: `include_labels` now flows through the entire pipeline serialization chain. (#39)
- **EVO-984**: credential fallback + eager webhook for Evolution Go. (#41)
- **EVO-1055**: new endpoint `GET /api/v1/evolution/health` that proxies to `${api_url}/` of Evolution API and returns the upstream JSON. The frontend `EvolutionService.healthCheck` relied on this route to validate the configured URL before creating a WhatsApp channel; without it, every Evolution API channel creation failed with 404 and "Health check failed" with no path forward. The controller mirrors the `Net::HTTP` pattern from `authorizations_controller#check_server_status` (5s open/read timeout). (#45)
- **EVO-985**: `BACKEND_URL` pointing to `localhost` is blocked in production. (#30)
- **EVO-996**: preserves `in_reply_to` when the parent message has not yet been resolved. (#31)
- **EVO-1012**: exposes `thumbnail` and wires avatar fetch through Evolution API. (#28)
- **WhatsApp groups**: group messages are now ingested into a single conversation per group (no longer one per participant). (#29)

#### Idempotent migrations (PR #21)
Four migrations made safe for re-run in PROD with drifted schemas (or partially migrated due to a previous crash). Without this, deploys in existing environments could break with `PG::DuplicateTable` / `PG::UndefinedColumn`. Sourcery review applied with individual guards for each `add_index` / backfill (no blind early returns).
- `20251119155458_make_attachment_polymorphic.rb` — `column_exists?` guards on the polymorphic add_index.
- `20251117132621_add_type_to_contacts.rb` — `add_index` and backfill of `Contact.where(type: nil)` separated from the column guard; also creates the composite index `idx_contacts_name_type_resolved` if the `type` column already exists (cooperation with migration `20241020`).
- `20260414120000_create_user_tours.rb` — `unless table_exists?` on `create_table` + `unless index_exists?` on each `add_index`, instead of the early return that skipped indexes.
- `20251114150000_add_sentiment_analysis_fields_to_facebook_comment_moderations.rb` — `if_not_exists: true` on all added columns.

#### Migration ordering — `OptimizeContactsPerformance`
- Migration `20241020000100_optimize_contacts_performance.rb` (from PR #40) had an October/2024 timestamp — fresh installs ran it before `AddTypeToContacts` (`20251117`), trying to create an index on `contacts(name, type, id)` when the `type` column did not yet exist → `PG::UndefinedColumn`. Fix: `IF NOT EXISTS` on all `CREATE INDEX` and a `column_exists?(:contacts, :type)` guard for the composite index. `AddTypeToContacts` backfills that index after adding the column. No timestamp change (existing PROD intact).

#### Contact import / Roles (PR #40)
- **CPF/CNPJ sanitization on import** via new `sanitize_tax_id` method in `ContactManager`. Formatted CPF/CNPJ are stored with digits only.
- **Performance optimization**: `Contact.resolved_contacts` migrated to `LEFT JOIN`, count cache in the controller (1 minute), new indexes on `contact_inboxes` and `contacts`.
- **`Role` and `UserRole` models** introduced in the CRM to consume roles synchronized from `evo-auth-service` (support for role-based admin notifications).
- **`format_phone_number`** preserved the `+` prefix.
- **Import CSV** with expanded format (person/company, tax_id, social profiles, custom_attributes).

#### Database / DevOps
- **db**: dropped FKs to the removed `users` table (which were blocking `db:migrate`). (#3)
- **evolution_go**: `api_url` and `admin_token` now persist in `provider_config` from `GlobalConfig`. (#5)
- **whatsapp_cloud**: removed avatar fetch from Evolution Go on the Cloud inbound flow.

### Changed

- **CI**: workflow now also publishes `develop` images for staging.

## [v1.0.0-rc1] - 2026-04-24

### Added

- First public release candidate of `evo-ai-crm-community`.
- `Api::V1::*` REST API with controllers for conversations, contacts, pipelines, agents, OAuth applications, teams, channels, etc.
- Integration with `evo-ai-core-service` (agents) via `EvoAiCoreService`.
- Event listeners via `Wisper` + `SyncDispatcher` with broadcasts to `ActionCableListener`.
- Serializers `MessageTemplate`, `Team`, `Pipeline`, etc.
- Background jobs (`Webhooks::WhatsappEventsJob`, `ActionCableBroadcastJob`).
- Master database schema as the source of truth for setup.

---

[Unreleased]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc6...HEAD
[v1.0.0-rc6]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc5...v1.0.0-rc6
[v1.0.0-rc5]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc4...v1.0.0-rc5
[v1.0.0-rc4]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc3...v1.0.0-rc4
[v1.0.0-rc3]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc2...v1.0.0-rc3
[v1.0.0-rc2]: https://github.com/evolution-foundation/evo-ai-crm-community/compare/v1.0.0-rc1...v1.0.0-rc2
[v1.0.0-rc1]: https://github.com/EvolutionAPI/evo-ai-crm-community/releases/tag/v1.0.0-rc1
