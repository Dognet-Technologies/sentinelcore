# 06 — Data Model

PostgreSQL 15+. ~69 tables created by 76 ordered migrations in `vulnerability-manager/migrations/`. This chapter maps the schema by domain; column-level truth is the migration files themselves.

## Conventions

- **Primary keys**: UUID (v4).
- **Timestamps**: `TIMESTAMPTZ` (migration 006 converted legacy columns).
- **Addresses**: native `INET`/CIDR types (migration 004).
- **Soft delete**: `deleted_at` on core entities (030, 031) with cascading semantics (034); hard purge available via the DB admin API.
- **Rule conditions / flexible metadata**: JSONB with GIN indexes where filtered.
- **DB-side logic**: triggers and functions for risk scoring, mention extraction, timeline writes, SLA breach marking, device→asset sync.
- **SQLx offline**: query metadata under `.sqlx/` must be regenerated (`cargo sqlx prepare`) when queries change.

## Domains

### Identity & access

| Table | Purpose |
|---|---|
| `users` | Accounts: credentials (Argon2 hash), role enum, 2FA secret, skills array, reputation, email verification, soft delete |
| `user_sessions` | Per-device sessions: token, IP (`INET`), user agent, expiry, revocation |
| `user_settings` | UI/preferences per user (108) |
| `user_notifications` | In-app notification center (105) |
| `user_skills` / skills catalog | Skills used by assignment matching (101) |
| `password_reset_tokens` | SHA-256 hashed reset tokens with expiry (027) |
| `user_permissions` | Granular grants with scope, expiry, grant/revoke audit (007) |
| `ip_whitelist` | CIDR whitelist entries, global/user/team scope (007) |
| `api_keys` | Personal API keys |
| `reputation_events` | Reputation point history |

### Vulnerabilities

| Table | Purpose |
|---|---|
| `vulnerabilities` | Core entity: CVE, title, severity, CVSS score/vector, EPSS, risk_score/risk_tier, host/port/service, status, assignments, SLA fields, reopen tracking (120), fingerprint for dedup (112) |
| `vulnerability_sources` | Multi-scanner source records per finding (112) |
| `vulnerability_timeline` | Status/change history (104, 110) |
| `vulnerability_comments` | Threaded comments, mentions (JSONB), attachments, internal flag |
| `vulnerability_rule_matches` | Audit of assignment-rule matches |
| `resolution_scoring_history` / resolution stats | Recorded and verified resolutions, leaderboard inputs (029) |
| `risk_acceptance` | Acceptance lifecycle: status, approver, expiry, reviews (025) |

### Assets & network

| Table | Purpose |
|---|---|
| `assets` | Asset registry: IP, hostname, OS, tags, network zone, criticality, `network_device_id` FK to discovered device (113), auto-created flag (121) |
| `network_devices` | Discovered devices: type, model (117), assignment (`assigned_at`, 116), tracking fields (039) |
| `network_topology` / links | Device adjacency for the topology graph (003) |
| `network_ranges` | Known ranges/zones |
| `device_metrics_daily` | Daily per-device snapshots for trends (115) |
| `scanner_imports` | Import audit: scanner, file, counters, errors (022) |

Migration 123 added the device→asset sync that makes `assets.network_device_id` the single source of truth joining discovery and scan imports.

### Teams & assignment

| Table | Purpose |
|---|---|
| `teams` | Teams |
| `team_members` | Membership with per-team role and `user_id` (020, 021, 026, 103, 106 hardened constraints) |
| `assignment_rules` | JSONB conditions, priority, team target, role/skill filters, load-balancing strategy (024) |
| `system_settings` (assignment policy keys) | Global auto/manual assignment policy + topology precedence (124) |
| auto-assignment tracking | Rule execution tracking (102) |

### Remediation

| Table | Purpose |
|---|---|
| `remediation_plans` | Plans: title, status, priority, due date, `device_ids` (036), linked vulnerabilities (033) |
| `remediation_comments` | Plan discussion, internal flag (037) |

Migrations 119 and 122 **removed** the legacy RBRE columns and dead remediation task tables from the earlier Risk-Based Remediation Engine design.

### Notifications

| Table | Purpose |
|---|---|
| `notification_channels` | Channel records: type, JSONB configuration, enabled flag (015) |
| `notification_rules` | JSONB conditions, priority, channels, recipients, template, throttle, quiet hours (015) |
| `notification_history` | Delivery log |
| `notification_throttle` | Per-rule last-sent timestamps |

Migration 111 extended the notification type enum; 110 added helper functions shared with the timeline.

### Integrations

| Table | Purpose |
|---|---|
| `jira_configurations` | JIRA endpoints + credentials, project mapping (016) |
| `jira_tickets` | Finding↔ticket links, sync status, retry state (016) |
| `soar_webhooks` | Outbound webhook definitions (017) |
| `plugins` (registry) + `plugins.config` | Installed plugin metadata; OpenVAS connector config with AES-GCM-encrypted GMP credentials (125) |

### Compliance & reporting

| Table | Purpose |
|---|---|
| `compliance_frameworks` + definitions | Framework/control catalogs (018, 023) |
| `compliance_reports` | Generated compliance reports with score |
| `reports` | Report definitions, generation status, artifacts |

### Audit & system

| Table | Purpose |
|---|---|
| `audit_logs` | Full audit trail (actor, action, entity, metadata) |
| `system_metadata` | Worker bookkeeping (e.g. EPSS last update) (109) |
| `system_settings` | UI-editable settings: network discovery scheduler (107), auto-rescan (114), logging (level/destination/retention), assignment policy (124) |

## Key triggers & functions

| Object | Fires on | Effect |
|---|---|---|
| `calculate_risk_score()` trigger | INSERT/UPDATE on `vulnerabilities` | Recomputes risk_score, risk_tier, sla_deadline (118 fixed edge cases) |
| `extract_mentions()` trigger | INSERT/UPDATE on comments | Parses `@username`, stores mention UUIDs, feeds notifications (100 fix) |
| `mark_sla_breaches()` function | hourly worker / admin endpoint | Marks `sla_breached` on expired open findings |
| device→asset sync trigger | discovery writes | Keeps `assets` aligned with `network_devices` (123) |
| timeline helpers | status changes | Writes `vulnerability_timeline` and user notifications (110) |

## Migration notes

- Numbering is ordered but not dense (e.g. jump to 099/100+, seeds at `099_realistic_workflow_seed.sql` and `999_seed_data.sql`).
- Seed migrations provide a realistic demo workflow; production deployments should review them before applying.
- The repo currently runs migrations manually/by tooling — the `sqlx::migrate!` call in `main.rs` is disabled by design; do not run blind `sqlx migrate run` against an existing database without checking the tracking table state.
