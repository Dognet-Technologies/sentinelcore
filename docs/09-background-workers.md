# 09 — Background Workers

All workers are Tokio tasks spawned by `main.rs` at startup, sharing the SQLx pool with the HTTP layer. Coordination happens exclusively through PostgreSQL — there is no external queue. Source: `src/workers/` (11 modules) plus the remediation executor in `src/network/`.

| # | Worker | Module | Schedule | Purpose |
|---|---|---|---|---|
| 1 | SLA breach checker | `sla_checker.rs` | every 1 h | Marks `sla_breached` on open findings past `sla_deadline` (via `mark_sla_breaches()`), feeding breach notifications |
| 2 | JIRA sync | `jira_sync.rs` | every 15 min | Processes pending ticket syncs in both directions, with retry state per ticket |
| 3 | Notification digest | `notification_digest.rs` | every 24 h | Aggregates digest-mode notifications into a summary email |
| 4 | NVD enrichment | `nvd_api.rs` | every 24 h | Fetches CVE metadata (CVSS vector, CWE, references) from the NVD 2.0 API; 6 s spacing between calls (free-tier rate limit) |
| 5 | EPSS updater | `epss_updater.rs` | every 24 h | Downloads the FIRST.org EPSS CSV (~200k CVEs) and batch-updates `epss_score`; risk trigger cascades tier/SLA updates |
| 6 | Report generator | `report_generator.rs` | poll every 10 s | Picks up queued report generation jobs and renders artifacts (PDF/CSV/JSON/XML) |
| 7 | Auto Network Discovery scheduler | `auto_rescan.rs` | tick 60 s | Reads `system_settings` live (target, interval hours, scan type, timing, custom args) and launches nmap discovery when due |
| 8 | Device metrics snapshot | `device_metrics_snapshot.rs` | every 1 h | Writes daily per-device metrics (`device_metrics_daily`) powering trend charts |
| 9 | Log retention | `log_retention.rs` | every 30 min | Rotates/compresses the application log per retention settings (e.g. 7 days / 500 MB, gzip in place); retention values read live from settings |
| 10 | Assignment scheduler | `assignment_scheduler.rs` | every 5 min | Applies the auto-assignment policy: evaluates rules against unassigned findings, honoring topology/device precedence |
| 11 | OpenVAS poller | `openvas_poller.rs` | base tick 60 s | Polls the configured GVM instance per `poll_interval_minutes`; imports completed reports through the OpenVAS importer |
| 12 | Remediation executor | `network/remediation_executor.rs` | continuous | Executes remediation actions/tasks from plans and records outcomes |

## Operational notes

- **Settings-driven workers** (7, 9, 11) re-read their configuration from the database on each tick — changes from the Settings UI apply without restart. Logging **level/destination** (as opposed to retention) are applied at startup only and require a service restart.
- **Failure behavior**: workers log and retry on the next tick; a failing external dependency (NVD, EPSS, JIRA, GVM) degrades that integration without affecting the HTTP API.
- **Startup checks**: network discovery prerequisites (nmap availability/privileges) are verified once at boot; failures produce warnings, not aborts.
- **Resource sharing**: all workers draw from the same connection pool (default max 30) — long EPSS batch updates are chunked to avoid starving the API.
