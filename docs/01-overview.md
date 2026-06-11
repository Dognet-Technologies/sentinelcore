# 01 — Overview

## What SentinelCore is

SentinelCore is a **self-hosted vulnerability management platform** for internal security teams. It centralizes vulnerability data from network discovery and third-party scanners, scores it by real-world risk, assigns it to the right people, tracks remediation against SLA deadlines, and produces the audit trail and reports that compliance work requires.

The product is built around a single operational loop:

```
discover → import → score → assign → remediate → verify → report
```

Every stage of that loop is backed by a concrete handler, database table, and UI page — see [02 — Architecture](02-architecture.md) for how the pieces connect.

## What it does

- **Network discovery** — built-in nmap-based scanning with a configurable profile (scan type, timing template, ports, custom args), a recurring scheduler, and a live topology map of discovered devices.
- **Scan import** — parses result files from 10 third-party scanners (Qualys, Nessus, Burp Suite, OpenVAS/GVM, Nexpose/InsightVM, OWASP ZAP, Nmap, Nikto, Trivy, Grype), normalizes severity, deduplicates findings, and links them to assets.
- **Direct scanner connectivity** — a built-in OpenVAS/GMP connector polls a GVM instance on a schedule and imports completed reports without manual file export.
- **Risk scoring** — composite 0–100 score from CVSS base, EPSS exploit probability, business impact, asset exposure, and exploit availability, with hard overrides for zero-days, ransomware-targeted CVEs, and actively exploited vulnerabilities.
- **SLA tracking** — risk tier maps to a remediation deadline (Critical 1d, High 7d, Medium 30d, Low 90d); a worker marks breaches and notification rules fire progressive warnings.
- **Assignment** — manual assignment to teams/users, plus a rule-based auto-assignment engine with skill matching and load balancing, governed by a global auto/manual policy.
- **Remediation plans** — group vulnerabilities and devices into executable plans with status tracking, comments, and post-remediation verification.
- **Collaboration** — threaded comments with `@mentions`, per-user in-app notifications, resolution scoring with user and team leaderboards.
- **Notifications** — rule-based routing engine (JSONB conditions, priorities, throttling, quiet hours) delivering over email (SMTP), Slack, and Telegram.
- **Integrations** — bi-directional JIRA sync with auto-ticketing, NVD CVE enrichment, daily EPSS refresh, outbound SOAR webhooks.
- **Reporting** — vulnerability reports (PDF/CSV/JSON/XML export), management reports, compliance reports against framework definitions, technical heatmaps, executive dashboard.
- **Security & audit** — JWT auth in httpOnly cookies, CSRF protection, TOTP 2FA, session management with remote revocation, full audit log, IP whitelisting, granular user permissions.

## What it does not do

Being explicit about boundaries avoids wrong expectations:

- **It is not a scanner.** Apart from nmap-based network/port discovery, SentinelCore does not detect vulnerabilities itself — it ingests results from external scanners.
- **No multi-tenancy.** One installation serves one organization. There is no tenant isolation layer.
- **No HA / clustering.** Designed for single-host deployment with one PostgreSQL instance. No horizontal scaling story yet.
- **No container-first deployment.** Deployment targets a Linux host or a packaged VM (see `packer/`); Docker images are not the supported path in v1.0.x.
- **No agent.** There is nothing to install on monitored endpoints; visibility comes from network scans and imported scanner data.
- **Notification channels are email, Slack, Telegram.** Channel records for other types can be stored, but only these three have delivery implementations today.
- **No automated patching at scale.** A remediation executor worker exists for plan tasks, but SentinelCore is not a patch management system.
- **Plugin runtime is in-memory and synchronous.** Dynamic loading of native plugins (.so/.dll), sandboxing, and a marketplace are planned (v1.0.5 roadmap), not present.
- **No built-in LDAP/SSO.** Authentication is local (username/password + optional TOTP); SAML/OIDC federation is not implemented.

## Status

v1.0.1, **beta**. Core flows are stable on a single-host deployment. Version line `develop/v1.0.1-*` is the active development series.

## Key numbers (current codebase)

| Metric | Value |
|---|---|
| HTTP API endpoints | 188 |
| Backend (Rust) | ~31,000 LOC |
| Frontend (TypeScript/React) | ~32,000 LOC |
| Database tables | ~69 (76 migrations) |
| Background workers | 12 |
| Scanner importers | 10 |
| Notification channels (implemented) | 3 |
| Roles | 3 (`admin`, `team_leader`, `user`) |
