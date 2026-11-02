<div align="center">

# SentinelCore

**Vulnerability Management Platform for Security Teams**

Track. Prioritize. Remediate. — across every asset on your network, with the audit trail your auditors expect.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)](https://www.rust-lang.org/)
[![Axum](https://img.shields.io/badge/Axum-0.6-blueviolet.svg)](https://github.com/tokio-rs/axum)
[![React](https://img.shields.io/badge/React-18-blue.svg)](https://reactjs.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15+-336791.svg)](https://www.postgresql.org/)
[![Status](https://img.shields.io/badge/status-beta-yellow.svg)]()
[![Version](https://img.shields.io/badge/version-2.0.0-success.svg)]()

</div>

> **Stability disclaimer.** SentinelCore is in **beta**. Core flows are stable on a single-host deployment with a dedicated PostgreSQL instance. Multi-tenant, HA, and containerized deployments are not yet supported. Use the issue tracker for production blockers.

---

## What v2.0.0 brings

2.0.0 builds on the 1.2.0 line (native **MCP server** with read/write tools, granular notification preferences, VM appliance first-boot fix) with a round of operator-facing work. The full detail is in the [User Manual](docs/user-guide/README.md); the headlines are:

- **Interactive network topology** — box selection, rigid group moves, Ctrl+wheel zoom, pan, and *Fit*; personalised manual links (shape, stroke, end shapes, colour, TAG such as *lateral movement* / *monitored segment*, animation); scanner-discovered links drawn animated; subnet frames that follow their hosts, move by their header, and collapse into a summary card; **hierarchical** and **circular** views grouped by subnet, with a saved layout per view; a safe area so nodes never end up under the header.
- **Interactive dashboard** — every column of *Vulnerability Trend* opens that day's panel: a rose chart by severity, headline numbers, and internal links to the most critical vulnerabilities and most exposed hosts.
- **A risk score you can read** — the host *Input del risk score* card lists only the fields that really feed the engine, with the points each value contributes; duplicated fields were unified (`criticality`, `is_internet_facing` and `has_public_ip` are now derived — migration 157).
- **Remediation plans, rebuilt around vulnerabilities** — a plan is now the explicit list of the vulnerabilities to fix, not whole hosts (**breaking**: migration 161, `/remediation-plans/:id/devices*` replaced by `/vulnerabilities`, `/vulnerabilities/remove`, `/scope` and `/selection/preview`). Pick them with combinable criteria (network/CIDR, host type, owner team, exposure, risk tier, severity, KEV, CVE, free text), one by one, all results, or per host (*all of the asset's vulnerabilities* / *risk X or higher*); new vulnerabilities on a plan's host no longer join it by themselves; existing plans are back-filled once with what they covered. Plans still complete by themselves the moment the last vulnerability is resolved (migration 158). Each host's *Remediation Summary* counts only that host's plans.
- **Host clones** — a host can declare a clone in a *testing* and/or *pre-production* network (host/URL, network/CIDR, dog_agent id, and an "aligned with production" flag) so remediations can be tried there first; informational today, meant for the cross-tool integrations (migration 159).
- **KEV and NVD on the vulnerability page** — a threat-intelligence card (vendor, product, due date, required action, ransomware use; migration 160) with KEV/NVD events in the timeline, and an admin action to run both updaters on demand. Table toolbars gained a working *Columns* picker, and every date is shown in European format.
- **Comments** — threads of any depth, `@mention` autocompletion, and only the mentioned users are notified.
- **Realtime** — Server-Sent Events refresh lists, notifications and dashboards without a reload.
- **Security** — session revocation (password change, lock, delete), per-IP rate limits on login / 2FA, TOTP anti-replay, network scans through a root-owned wrapper with an option allowlist, validated Slack webhook URLs, and audit-log visibility by role.
- **Themes** — all 11 themes meet WCAG AA contrast for text and severity colours (enforced by a test).
- **Signed releases** — tagging a version builds the tarball and the VM images in CI and publishes them with `SHA256SUMS` and a GPG signature (see [packaging/README.md](packaging/README.md) and chapter 1 of the manual).

## What it actually does

SentinelCore is built around a single loop:

```
discover → import → score → assign → remediate → report
```

Each step has a real handler, a real table, and a real UI — not a dashboard tile masquerading as a feature.

### Discovery and topology

- Built-in `nmap`-based network discovery (configurable scan profile + scheduler).
- Interactive topology map: grouped subnets, hierarchical / circular views, personalisable links and animated discovered links.
- 10 third-party scanner importers: **Qualys**, **Nessus**, **Burp Suite**, **OpenVAS/GVM**, **Nexpose / InsightVM**, **OWASP ZAP**, **Nmap**, **Nikto**, **Grype**, **Trivy**.

### Risk and SLA

- Composite risk score combining CVSS base, EPSS probability, business impact, asset exposure, and exploit availability.
- Severity tiers map directly onto SLA windows (Critical 1d, High 7d, Medium 30d, Low 90d) with 75% / 90% / 100% breach signals.
- Override channel for zero-days, ransomware-tied CVEs, and entries in CISA KEV.
- KEV details card on the vulnerability page (vendor, due date, required action, ransomware use) with KEV/NVD events recorded in the timeline.

### Collaboration

- Comment threads of any depth on vulnerabilities and remediation plans, with `@mention` autocompletion (only the mentioned users are notified).
- Remediation plans with host picker, draft-only host editing, and automatic completion at 100% resolved.
- Multi-channel notification routing: email, Slack, Telegram, Microsoft Teams, generic webhook, PagerDuty, OpsGenie.
- Throttling and quiet-hours to keep the channel signal-to-noise sane.

### MCP server (read/write)

- Native **Model Context Protocol** server embedded in the backend — single endpoint `POST /api/mcp`, JSON-RPC 2.0, no external gateway.
- **Read tools**: `list_vulnerabilities`, `get_vulnerability`, `get_risk_summary`.
- **Write tools**: `assign_vulnerability`, `update_vulnerability_status`, `accept_risk`, `trigger_scan` — each gated by a per-API-key scope guardrail.
- Same contract shared across the Dognet Technologies suite (SentinelCore, FireDog, CyberShepherd) — see [docs/11-mcp-contract.md](docs/11-mcp-contract.md).

### Integrations

- Bi-directional **JIRA** sync (status, priority, custom field mapping).
- **NVD** enrichment worker for CVE metadata.
- **EPSS** daily score refresh.

### Authn/z and audit

- JWT auth with `httpOnly` cookies + CSRF token on state-changing requests.
- RBAC: `admin`, `team_leader`, `user`.
- TOTP-based 2FA (a used code is never accepted twice), session tracking with remote revocation, per-IP rate limiting on login.
- Audit log for compliance reporting (PCI-DSS, ISO 27001, SOC2, HIPAA tags): full for `admin` and `team_leader`, own actions only for `user`.

---

## Architecture

```
┌──────────────────────────┐         ┌──────────────────────────────────┐
│   React 18 + MUI 5       │         │       Axum 0.6 (Rust)            │
│                          │  HTTPS  │                                  │
│ TanStack Query, axios    │ ──────► │ sqlx 0.8 (compile-time queries)  │
│ Cytoscape (topology)     │  cookie │ Tower middleware (CSRF, RBAC)    │
│ ECharts, Recharts        │  + CSRF │ JWT (httpOnly cookie)            │
└──────────────────────────┘         └────────────┬─────────────────────┘
                                                  │
                                                  ▼
                                     ┌──────────────────────────┐
                                     │   PostgreSQL 15+         │
                                     │   91 migrations          │
                                     │   JSONB, triggers, GIN   │
                                     └──────────────────────────┘
                                                  ▲
                                                  │
                                     ┌────────────┴─────────────┐
                                     │   Background workers     │
                                     │ ─────────────────────────│
                                     │ assignment_scheduler     │
                                     │ auto_rescan              │
                                     │ critical_alert           │
                                     │ device_metrics_snapshot  │
                                     │ epss_updater             │
                                     │ jira_sync                │
                                     │ kev_updater              │
                                     │ log_retention            │
                                     │ notification_digest      │
                                     │ nvd_api                  │
                                     │ openvas_poller           │
                                     │ remediation_plan_progress│
                                     │ report_generator         │
                                     │ sla_checker              │
                                     │ weekly_report            │
                                     └──────────────────────────┘
```

**Backend** (`vulnerability-manager/`)
Rust 1.75+, Axum 0.6, sqlx 0.8 (offline cache committed in `.sqlx/`), tokio 1, jsonwebtoken 10, argon2, tracing + `tracing-appender` for file logs.

**Frontend** (`vulnerability-manager-frontend/`)
React 18, TypeScript 4.9, MUI 5, TanStack Query 5, Cytoscape (network topology), ECharts + Recharts (analytics), Framer Motion, three.js. Built with Create React App (`react-scripts`).

**Database**
PostgreSQL 15+, 91 migrations under `vulnerability-manager/migrations/`. Heavy use of `JSONB`, triggers (e.g. `network_devices.assigned_at`), and GIN indexes (e.g. team/user `skills`).

---

## Quick start (single host)

These steps assume a fresh Debian 12 host with `sudo` and a non-root deploy user.

### 1. System dependencies

```bash
sudo apt update && sudo apt install -y \
    git curl build-essential pkg-config \
    libssl-dev libpq-dev \
    postgresql-15 nginx nmap
```

### 2. Rust + Node

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### 3. Database

```bash
sudo -u postgres psql -c "CREATE USER sentinelcore WITH PASSWORD 'change-me';"
sudo -u postgres psql -c "CREATE DATABASE sentinelcore_db OWNER sentinelcore;"
```

### 4. Backend

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore/vulnerability-manager

cat > .env <<'EOF'
DATABASE_URL=postgresql://sentinelcore:change-me@localhost/sentinelcore_db
SERVER_HOST=0.0.0.0
SERVER_PORT=8080
JWT_SECRET=replace-this-with-a-long-random-string
JWT_EXPIRATION=3600
CORS_ALLOWED_ORIGINS=http://localhost:3000
LOGGING_LEVEL=info
LOGGING_DESTINATION=/var/log/sentinelsuite/sentinelcore/app.log
EOF

cargo install sqlx-cli --no-default-features --features native-tls,postgres
sqlx migrate run

SQLX_OFFLINE=true cargo build --release
```

### 5. Frontend

```bash
cd ../vulnerability-manager-frontend
npm install
npm run build      # production bundle ends up in build/
```

### 6. Discovery permissions

The discovery worker needs raw sockets and OS detection, which require root. The service does **not** run as root and does not get `sudo` on `nmap` itself: `install.sh` installs a root-owned wrapper, `/usr/local/libexec/sentinelcore/scan`, and a sudoers fragment that authorises **only** that script. The wrapper accepts `nmap` / `arp-scan` with an explicit **allowlist of options** and validated targets (no `-iL`, `-oN`, NSE scripts…) and runs them with a clean environment. Installing from the release tarball (`install.sh` / `upgrade.sh`) does this for you; a manual install should copy `packaging/templates/sentinelcore-scan` and `install-scan-privileges.sh`.

### 7. Reverse proxy (Nginx)

```nginx
server {
    listen 80;
    server_name your.domain;

    root /opt/sentinelcore/vulnerability-manager-frontend/build;
    index index.html;

    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location / {
        try_files $uri /index.html;
    }
}
```

For TLS use `certbot --nginx -d your.domain`.

### 8. First login

Open `http://<host>/`, log in with the seeded admin (printed once by the migration), and **immediately**:

1. Change the admin password.
2. Enable 2FA (Settings → Security).
3. Tighten `CORS_ALLOWED_ORIGINS`.
4. Configure notification channels.
5. Set the discovery `subnet` and schedule in Settings → Network Discovery.

---

## Configuration

All runtime configuration lives in `vulnerability-manager/.env`. The keys we touch most:

| Key | Default | Purpose |
|-----|---------|---------|
| `DATABASE_URL` | — | PostgreSQL connection string. Required. |
| `SERVER_HOST` / `SERVER_PORT` | `0.0.0.0` / `8080` | Listen address. |
| `JWT_SECRET` | — | HMAC secret for tokens. Required, long random string. |
| `JWT_EXPIRATION` | `3600` | Token lifetime in seconds. |
| `CORS_ALLOWED_ORIGINS` | — | Comma-separated origins. |
| `RATE_LIMIT_ENABLED` | `true` | Per-IP token bucket. |
| `LOGGING_LEVEL` | `warn` | `error` / `warn` / `info` / `debug`. |
| `LOGGING_DESTINATION` | `/var/log/sentinelsuite/sentinelcore/app.log` | Log file path; `journal` for systemd journal. |
| `LOG_RETENTION_DAYS` | `90` | Files older than this are pruned by the `log_retention` worker. |

Discovery and rescan parameters (subnet, schedule, scan type, timing, port list, custom args) are stored in the `auto_rescan_settings` table and edited from **Settings → Network Discovery** in the UI.

---

## Repository layout

```
sentinelcore/
├── vulnerability-manager/              # Rust backend (Axum 0.6 + sqlx 0.8)
│   ├── src/
│   │   ├── api/                        # Route definitions (188 endpoints)
│   │   ├── handlers/                   # Request handlers
│   │   ├── mcp/                        # MCP server (JSON-RPC, read + write tools)
│   │   ├── network/                    # Discovery scanner + topology
│   │   ├── scanners/                   # 10 third-party importers
│   │   ├── workers/                    # 15 background tokio workers
│   │   ├── notifications/              # Email / Slack / Telegram
│   │   └── middleware/                 # CSRF, RBAC, rate limit
│   ├── migrations/                     # 91 SQL migrations
│   ├── .sqlx/                          # Committed compile-time query cache
│   └── plugins/                        # First-party plugin examples
│
├── vulnerability-manager-frontend/     # React 18 + MUI 5 + TanStack Query
│   ├── src/
│   │   ├── api/                        # Shared axios client + per-domain APIs
│   │   ├── components/                 # 43 components (incl. NetworkTopology)
│   │   ├── pages/                      # 27 pages
│   │   ├── contexts/                   # Auth + global state
│   │   └── hooks/
│   └── public/
│
└── docs/                               # Technical documentation (see below)
```

---

## Documentation

Full technical documentation lives in [`docs/`](docs/):

[Overview](docs/01-overview.md) · [Architecture](docs/02-architecture.md) · [Features](docs/03-features.md) · [API Reference](docs/04-api-reference.md) · [Roles & Permissions](docs/05-roles-and-permissions.md) · [Data Model](docs/06-data-model.md) · [Integrations](docs/07-integrations.md) · [Plugin System](docs/08-plugin-system.md) · [Background Workers](docs/09-background-workers.md) · [Technical Specs](docs/10-technical-specs.md)

User guide (Italian): [docs/user-guide](docs/user-guide/README.md) — the PDF edition is built with `docs/user-guide/build-pdf.sh`.

Deploying on a fresh Debian 13 VM? Follow [INSTALL.md](INSTALL.md).

---

## Development

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore

# Backend
cd vulnerability-manager
cp .env.example .env       # then edit DATABASE_URL etc.
sqlx migrate run
cargo run

# Frontend (new terminal)
cd ../vulnerability-manager-frontend
npm install
npm start                  # dev server on :3000, proxies /api to :8080
```

**Quality gates:**

```bash
# Rust
cargo fmt
cargo clippy --all-features -- -D warnings
cargo test
cargo audit

# TypeScript
cd vulnerability-manager-frontend
npm run format
npm test
npm audit
```

**sqlx offline cache**

`sqlx::query!` and `sqlx::query_as!` macros are checked at compile time against the database. CI compiles with `SQLX_OFFLINE=true` against `.sqlx/`. After changing or adding a query:

```bash
cd vulnerability-manager
cargo sqlx prepare    # connects to $DATABASE_URL, regenerates .sqlx/
git add .sqlx
```

---

## Operations

### Logs

File logging is on by default at `/var/log/sentinelsuite/sentinelcore/app.log`. The `log_retention` worker rotates by **size (500 MB) or age (7 days)** using copy-truncate so the open file descriptor stays valid, then gzips the previous file. Files older than `LOG_RETENTION_DAYS` are pruned.

Live tail:

```bash
sudo tail -f /var/log/sentinelsuite/sentinelcore/app.log
# or via journal
sudo journalctl -u sentinelcore -f
```

### Backups

```bash
sudo -u postgres pg_dump sentinelcore_db | gzip > "backup_$(date +%Y%m%d).sql.gz"
```

Restore:

```bash
gunzip -c backup_YYYYMMDD.sql.gz | sudo -u postgres psql sentinelcore_db
```

### Updates

Use the `upgrade.sh` shipped in every release tarball (also for the VM appliance): it takes a database backup first, installs the new files, applies the migrations and checks health, rolling back automatically if the migrations fail. Verify the download first — see [packaging/README.md](packaging/README.md) and chapter 1 of the manual (`SHA256SUMS` + GPG signature).

```bash
tar xzf sentinelcore-<version>-linux-x86_64.tar.gz
cd sentinelcore-<version>-linux-x86_64
sudo ./upgrade.sh
```

Building from source instead? `git pull`, then `sqlx migrate run`, `SQLX_OFFLINE=true cargo build --release`, `npm run build` in the frontend, and restart the service. New migrations are written to be idempotent.

---

## Security

| Layer | What we do |
|-------|-----------|
| **Transport** | TLS terminated at Nginx + HSTS header (`max-age=31536000; includeSubDomains; preload`). |
| **Auth** | JWT in `httpOnly` cookie + CSRF token on POST/PUT/DELETE/PATCH. |
| **Passwords** | Argon2id. |
| **2FA** | TOTP (RFC 6238). |
| **CSP** | Strict default-src `'self'`; configurable per deployment. |
| **Rate limiting** | Per-IP limits on login, 2FA and registration; per-role request limits on the API. |
| **Sessions** | Revoked on password change, lock and deletion; inactivity timeout is per-user and is not kept alive by background polling. |
| **Network scans** | Run through a root-owned wrapper with an option allowlist and validated targets. |
| **SSRF / path injection** | All file paths canonicalized and verified to stay under their canonical base. Outbound HTTP targets validated by host. |
| **Audit log** | Every state-changing action writes an audit entry tied to the user. |

If you spot something, please **don't** open a public issue. Email `security@dognet.tech` instead.

Published advisories are listed in [SECURITY.md](SECURITY.md). Versions up to 2.0.0 are affected by [SC-2026-001](SECURITY.md#sc-2026-001): update to 2.0.1.

---

## Roadmap

**Shipped in 2.0.0**

- Interactive topology (selection, zoom, personalised links, grouped hierarchical / circular views, collapsible subnets).
- Dashboard day panel with rose chart and internal links; real-data *Trend* column.
- Host *Input del risk score* card with points per value; unified derived fields (migration 157).
- Remediation plans built on explicit vulnerabilities with multi-criteria selection, draft-only editing, add from Hosts / Vulnerabilities, instant auto-completion (migrations 158, 161); per-host Remediation Summary.
- CISA KEV / NVD details and timeline events; on-demand updaters; host clones in testing / pre-production (migrations 159, 160).
- Threaded comments with `@mention` autocompletion; realtime updates (SSE).
- Security hardening: session revocation, login rate limits, TOTP anti-replay, scan wrapper allowlist, Slack webhook validation, audit visibility by role.
- WCAG AA contrast for all themes.
- Signed, CI-built releases (tarball, qcow2, OVA, `SHA256SUMS` + GPG).

**Shipped in 1.2.0**

- **MCP server phase 2**: write tools (`assign_vulnerability`, `update_vulnerability_status`, `accept_risk`, `trigger_scan`) with per-API-key scope guardrails.
- Granular per-channel, per-event notification preferences.
- VM appliance (qcow2 / OVA) first-boot fix.

**Shipped in 1.1.0**

- MCP server phase 1 (read-only): `list_vulnerabilities`, `get_vulnerability`, `get_risk_summary` over `POST /api/mcp`.
- VM appliance builder (qcow2 + OVA packaging).

**Shipped in 1.0.1**

- Network Topology restyle on the SentinelCore Design System.
- Configurable nmap discovery with live scan progress.
- File logging + retention worker.
- Single source of truth for device ↔ vulnerability linkage.
- Inline pencil-per-card editing on the device detail page.
- CSRF middleware self-heal across restarts.

**In flight**

- Phase C: skill-based auto-assignment with "add skill" alert in the assignment dialog.
- Container scanning (Trivy / Grype) — importers already in tree, wiring up next.
- MCP contract rollout to FireDog and CyberShepherd (contract defined in [docs/11-mcp-contract.md](docs/11-mcp-contract.md), implementation in progress on each product).

**Considered, not committed**

- Per-user rate limiting.
- Multi-tenancy.
- Plugin SDK + first-class skill matching.
- Out-of-the-box k8s/Helm deployment.

---

## Roles

| Role | Can | Cannot |
|------|-----|--------|
| **admin** | Everything below + user/team management, system settings, CORS, rate limits, JIRA, notifications, audit log, manual SLA override. | — |
| **team_leader** | Manage team members, assign vulns to team, create reports, comment, change status. | Modify system settings. |
| **user** | View assigned vulns, change their status, comment, view dashboard, export. | Assign vulns, manage teams. |

---

## Contributing

Pull requests and issues are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before sending a PR — it covers branch naming, commit format (`<type>: <subject>`), and the dev/release line policy.

Two things that will save us all time:

1. Branch off `develop/v2.0.0`, not `main`. `main` only takes curated merges.
2. If you touch a sqlx query, commit the regenerated `.sqlx/` cache in the same PR.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built by **[Dognet Technologies](https://github.com/Dognet-Technologies)** · [dognet.tech](https://dognet.tech)

If SentinelCore helps your team sleep at night, a GitHub star is the quietest way to say thanks.

</div>
