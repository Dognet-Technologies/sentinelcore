# 03 — Features

Functional areas, in the order they appear in the vulnerability lifecycle.

## Network discovery & topology

- nmap-based discovery executed by the backend (`src/network/`), with a privileged wrapper (`sudo NOPASSWD` for nmap) so the service itself does not run as root.
- Configurable scan profile from Settings: scan type, nmap timing template, port selection, optional custom arguments — with a live preview of the resulting nmap command.
- Recurring discovery via the auto-rescan scheduler (target, interval in hours, profile read live from `system_settings`).
- Live scan progress: status banner with elapsed time, devices found, current target; scan status endpoint (`GET /api/network/scan/:scan_id`).
- Topology graph with device nodes (type-specific icons/colors), links, subnet grouping; overlay of vulnerability counts per device (`/api/network/topology-with-vulnerabilities`).
- Device pages: details, editable system configuration (location, owner, criticality, model, OS), open ports with service detection and per-port vulnerability linkage, historical trends from daily metric snapshots.
- Device → asset synchronization: discovered devices are linked to assets through `assets.network_device_id`, so discovery and scanner imports converge on the same record (single source of truth for counts).
- Bulk device assignment to users/teams.

## Scanner import

- Upload of scan result files (`POST /api/scanners/import/:scanner/:format`, admin) or raw JSON import.
- 10 importers behind a common `ScannerPlugin` trait (validate + parse to `ParsedVulnerability`): Qualys, Nessus, Burp Suite, OpenVAS/GVM, Nexpose/InsightVM, OWASP ZAP, Nmap, Nikto, Trivy, Grype.
- Severity normalization to a 5-level scale (Critical/High/Medium/Low/Info), CVE/CWE extraction, CVSS score and vector capture, raw scanner payload retained for audit.
- Deduplication by fingerprint (CVE + host + port among non-closed findings); re-detections update `last_detected`; closed findings can reopen with reopen tracking (migration 120).
- Multi-source tracking: a finding reported by multiple scanners keeps all its sources (`vulnerability_sources`, migration 112).
- Import audit: every import is recorded in `scanner_imports` with counters (total, imported, updated, skipped, errors).

## Risk scoring

Composite score 0–100 calculated in `src/scoring/` and mirrored by a PostgreSQL trigger on insert/update:

```
score = CVSS component   (0–30)    severity bands of the CVSS base score
      + EPSS component   (0–25)    exploit probability bands
      + Business impact  (0–25)    asset criticality + sensitive data + revenue impact
      + Asset exposure   (0–15)    network zone: internet-facing → isolated
      + Exploit avail.   (0–5)     CISA KEV / public exploit / PoC / theoretical
```

Hard overrides (applied after the sum): zero-day → floor 90, ransomware-targeted → floor 85, actively exploited → +20, capped at 100.

Tiers and SLA windows:

| Tier | Score | SLA |
|---|---|---|
| Critical | 80–100 | 1 day |
| High | 60–79 | 7 days |
| Medium | 40–59 | 30 days |
| Low | 20–39 | 90 days |
| Info | < 20 | none |

Admins can recalculate a single score on demand (`POST /api/risk/vulnerabilities/:id/calculate`) and bulk-override severity/CVSS from the vulnerability list (context menu, bulk-edit endpoints).

## SLA tracking

- `sla_deadline = first_detected + sla_days(tier)`.
- Hourly worker marks breaches (`sla_breached`, breach timestamp) for open findings past deadline.
- Progressive notification stages via rules: 75% elapsed (warning), 90% (escalation), 100% (breach).
- Breach listing (`GET /api/risk/sla/breaches`) and manual breach marking for admins.

## Assignment

- **Manual**: assign a vulnerability to a team (`/assign`) or user (`/assign-user`); bulk-assign from the list view and from the topology (devices).
- **Automatic**: assignment rules with JSONB conditions on vulnerability and asset attributes, priority ordering, optional team-member role filter, required-skills matching (skills catalog on users), and a load-balancing strategy (least-loaded, round-robin, random).
- **Policy**: a global assignment policy (auto/manual) governs whether rules run automatically; topology/device assignment takes precedence where configured (migration 124). A dedicated assignment scheduler worker (5-minute tick) processes pending auto-assignments.
- Rules can be tested against sample data before enabling (`POST /api/assignment-rules/test`).
- "My vulnerabilities" view and per-user/per-team workload dashboards.

## Remediation

- Remediation plans group vulnerabilities and devices with status, due date, priority, and internal/external comments.
- Plan CRUD is admin-only; all authenticated users can view.
- A remediation executor worker processes executable plan tasks.
- Post-remediation verification: failed checks are surfaced as a dedicated card on the vulnerability detail page.
- Risk acceptance as an alternative outcome: request → approve/reject → periodic review → renew, with expiry (admin approves; everyone can view).

## Collaboration

- Threaded comments on vulnerabilities, assets/devices, and remediation plans; edit and soft-delete with audit.
- `@mention` extraction (DB trigger) generating in-app notifications and a personal mentions feed (`GET /api/mentions/me`).
- Per-user in-app notification center (`user_notifications`) plus a vulnerability timeline (status history).
- Resolution scoring: resolutions are recorded and verified, producing per-user statistics and user/team leaderboards.
- Reputation events on user profiles.

## Notifications

- Rule engine: JSONB conditions (eq, neq, gt/gte, lt/lte, in, contains) evaluated against vulnerability data; rule priority; throttling per rule; quiet hours; recipients by explicit email, user IDs, or team IDs; message templates with variable substitution.
- Channels: rule → channel records (`notification_channels`); implemented deliveries are **email (SMTP via lettre), Slack (incoming webhook), Telegram (bot API)**.
- Daily digest worker aggregates low-priority notifications into a summary email.
- Rules can be test-fired (`POST /api/notification-rules/:id/test`).

## Reporting & compliance

- Report definitions with on-demand generation (background worker), download, duplication, and email dispatch.
- Export formats: PDF, CSV, JSON, XML (`src/export/`).
- Management report generator (`POST /api/reports/generate-management`).
- Compliance reports against framework definitions stored in DB (PCI-DSS, ISO 27001, SOC2, HIPAA tags; migration 023), with control mapping and compliance scoring.
- Dashboards: operational stats, executive dashboard, technical heatmap, network dashboard.

## Administration & security

- User management: CRUD, lock/unlock, session listing and revoke-all, role changes (admin).
- Profile self-service: avatar, bio, language, password change, 2FA (TOTP enable/verify/disable), personal API keys (create/list/revoke), notification preferences, session list with per-session revocation.
- Security: IP whitelist (CIDR-aware), granular per-user permissions with expiry and revocation audit.
- Audit log: query/filter, stats, manual entries (`/api/audit/*`, admin).
- Database admin: status and hard-purge of soft-deleted data (`/api/admin/db/*`, admin).
- Settings: network discovery scheduler, logging (level/destination/retention), assignment policy — all persisted in `system_settings` and editable from the UI.

## Plugin system

See [08 — Plugin System](08-plugin-system.md). Built-in OpenVAS/GMP connector is documented in [07 — Integrations](07-integrations.md).
