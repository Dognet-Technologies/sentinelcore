# 07 — Integrations

## Scanner importers (file-based)

Ten parsers implement the `ScannerPlugin` trait (`src/scanners/mod.rs`): `metadata()`, `validate(data, format)`, `parse(data, format) → Vec<ParsedVulnerability>`, registered in a `ScannerRegistry`.

| Scanner | Module | Formats |
|---|---|---|
| Qualys | `qualys.rs` | XML |
| Tenable Nessus | `nessus.rs` | `.nessus` XML |
| Burp Suite | `burp.rs` | JSON |
| OpenVAS / GVM | `openvas.rs` | XML report |
| Rapid7 Nexpose / InsightVM | `nexpose.rs` | XML |
| OWASP ZAP | `owasp_zap.rs` | XML / JSON |
| Nmap | `nmap.rs` | XML (with CVE extraction from script output) |
| Nikto | `nikto.rs` | output formats per module |
| Trivy | `trivy.rs` | JSON |
| Grype | `grype.rs` | JSON |

Common normalized output (`ParsedVulnerability`): scanner-specific ID, title/description, 5-level severity, CVSS score + vector, CVE/CWE lists, tags, host/port/protocol/service, solution, references, detection timestamps, and the raw scanner payload for audit.

Import pipeline (admin API → `handlers/scanner_import.rs`): validate file → parse → normalize severity → fingerprint dedup (CVE+host+port among open findings) → upsert (`imported` vs `updated` vs `skipped` counters) → link/auto-create assets → DB trigger scores risk → assignment/notification/JIRA rules react. Every run is logged to `scanner_imports`.

## OpenVAS / GMP connector (built-in plugin)

Direct integration with a GVM/OpenVAS instance — no manual file export (migration 125, `src/integrations/openvas/`, `handlers/plugin_openvas.rs`, `workers/openvas_poller.rs`).

- **Transport**: `gvm-cli` (gvm-tools 26.x supported; the deprecated `[Auth]` config section is handled) talking GMP, with a temporary credentials file created `chmod 600`.
- **Credentials at rest**: GMP username/password encrypted with AES-GCM, key derived via SHA-256, stored in the plugin `config` JSONB.
- **Admin API**: `GET/PUT /api/plugins/openvas/config`, `POST /api/plugins/openvas/test` (connection test).
- **Poller worker**: 60s base tick; honors the configured `poll_interval_minutes`. Discovers completed GVM tasks/reports, fetches report XML, and funnels it through the standard OpenVAS importer — so dedup, scoring, assignment, and notifications behave exactly like a manual import.

## JIRA

Bi-directional issue tracking (`handlers/jira_integration.rs`, `workers/jira_sync.rs`, migration 016):

- Multiple JIRA configurations (base URL, credentials, project key) with connection testing.
- Manual ticket creation from a finding; auto-ticketing driven by rules (conditions on tier/severity), with priority mapping and templated descriptions (CVE, CVSS, risk score, asset, SLA deadline, backlink).
- Status synchronization in both directions with status mapping (Done/Resolved → resolved, In Progress → in_progress, …).
- Sync worker every **15 minutes** processing pending tickets with retry/backoff state on the ticket record.

## NVD enrichment

`workers/nvd_api.rs` — every 24h (and on demand after imports) queries the NVD REST API (`cves/2.0`) for findings missing metadata, respecting the free-tier rate limit (6s spacing between calls). Enriches CVSS vector, CWE IDs, references.

## EPSS

`workers/epss_updater.rs` — every 24h downloads the FIRST.org EPSS dataset (gzipped CSV, ~200k CVEs), decompresses, and batch-updates `epss_score` on matching findings. Score changes flow through the risk-score trigger, so tiers and SLA deadlines stay current. Last-run timestamp kept in `system_metadata`.

## Notification channels

Implemented senders in `src/notifications/`:

| Channel | Module | Mechanism |
|---|---|---|
| Email | `email.rs` | SMTP via `lettre` (TLS) |
| Slack | `slack.rs` | Incoming webhook |
| Telegram | `telegram.rs` | Bot API |

Channel records (`notification_channels`) hold a free-form `channel_type` + JSONB configuration; routing is described in [03 — Features](03-features.md#notifications). Other channel types can be stored but have **no delivery implementation** in v1.0.1.

## SOAR webhooks

Outbound generic webhooks (`handlers/soar_webhooks.rs`, migration 017): admin-defined endpoints that receive event payloads (HTTP POST) and can be triggered manually (`POST /api/soar/webhooks/:id/trigger`) for playbook integration on the SOAR side.

## nmap (local)

Network discovery shells out to `nmap` through a `sudo NOPASSWD` wrapper so privileged scan types (`-sV -O -sU -p-`) work without running the service as root. Requirements are verified at startup (`network::verify_system_requirements`); missing privileges degrade discovery features with a logged warning rather than failing the service.
