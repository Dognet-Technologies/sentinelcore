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
[![Version](https://img.shields.io/badge/version-1.0.1-success.svg)]()

</div>

> **Stability disclaimer.** SentinelCore is in **beta**. Core flows are stable on a single-host deployment with a dedicated PostgreSQL instance. Multi-tenant, HA, and containerized deployments are not yet supported. Use the issue tracker for production blockers.

---

## What v1.0.1 brings

The 1.0.1 release line ships a full **Network Topology restyle** plus a chain of operational improvements pulled from real deployment friction:

- **Hex/orb device nodes** with per-device-type colour and silhouette icons, link endpoint dots, subnet chips, and HUD overlays — built off the SentinelCore Design System in [`docs/NetworkTopology_restyle/`](docs/NetworkTopology_restyle/).
- **Slide-in device preview panel** on icon click — the Overview content surfaces without a full navigation, with an "Apri dettaglio completo" button to go deeper.
- **Inline pencil-per-card editing** on the System Configuration tab (location, owner, criticality, model, OS, …) — no separate management page.
- **Live scan progress banner** with elapsed time, devices found, and current target — replacing the "did it start? did it die?" guesswork.
- **Single source of truth for vuln counts** via `assets.network_device_id` — the network discovery pipeline and the scanner import pipeline now agree on the same device row.
- **Network Ports tab** with aggregated open ports, detected services, and per-port vuln linkage.
- **Configurable nmap discovery** in Settings: `scan_type`, timing template, port list, custom args — preview is a live nmap command string before save.
- **File logging system** with retention worker (7d / 500MB rotation, gzip in place), level and destination configurable from Settings.
- **`sudo NOPASSWD` nmap wrapper** so the discovery worker can do `-sV -O -sU -p-` scans without running the whole service as root.
- **CSRF middleware self-heal** so restarts don't 403 every in-flight browser session.

## What it actually does

SentinelCore is built around a single loop:

```
discover → import → score → assign → remediate → report
```

Each step has a real handler, a real table, and a real UI — not a dashboard tile masquerading as a feature.

### Discovery and topology

- Built-in `nmap`-based network discovery (configurable scan profile + scheduler).
- Topology graph with device nodes, link endpoints, and subnet grouping.
- 10 third-party scanner importers: **Qualys**, **Nessus**, **Burp Suite**, **OpenVAS/GVM**, **Nexpose / InsightVM**, **OWASP ZAP**, **Nmap**, **Nikto**, **Grype**, **Trivy**.

### Risk and SLA

- Composite risk score combining CVSS base, EPSS probability, business impact, asset exposure, and exploit availability.
- Severity tiers map directly onto SLA windows (Critical 1d, High 7d, Medium 30d, Low 90d) with 75% / 90% / 100% breach signals.
- Override channel for zero-days, ransomware-tied CVEs, and entries in CISA KEV.

### Collaboration

- Comment threads on vulnerabilities and remediation plans, with `@mention` notifications.
- Multi-channel notification routing: email, Slack, Telegram, Microsoft Teams, generic webhook, PagerDuty, OpsGenie.
- Throttling and quiet-hours to keep the channel signal-to-noise sane.

### Integrations

- Bi-directional **JIRA** sync (status, priority, custom field mapping).
- **NVD** enrichment worker for CVE metadata.
- **EPSS** daily score refresh.

### Authn/z and audit

- JWT auth with `httpOnly` cookies + CSRF token on state-changing requests.
- RBAC: `admin`, `team_leader`, `user`.
- TOTP-based 2FA, session tracking with remote revocation.
- Full audit log for compliance reporting (PCI-DSS, ISO 27001, SOC2, HIPAA tags).

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
                                     │   117 migrations         │
                                     │   JSONB, triggers, GIN   │
                                     └──────────────────────────┘
                                                  ▲
                                                  │
                                     ┌────────────┴─────────────┐
                                     │   Background workers     │
                                     │ ─────────────────────────│
                                     │ auto_rescan              │
                                     │ device_metrics_snapshot  │
                                     │ epss_updater             │
                                     │ jira_sync                │
                                     │ log_retention            │
                                     │ notification_digest      │
                                     │ nvd_api                  │
                                     │ report_generator         │
                                     │ sla_checker              │
                                     └──────────────────────────┘
```

**Backend** (`vulnerability-manager/`)
Rust 1.75+, Axum 0.6, sqlx 0.8 (offline cache committed in `.sqlx/`), tokio 1, jsonwebtoken 10, argon2, tracing + `tracing-appender` for file logs.

**Frontend** (`vulnerability-manager-frontend/`)
React 18, TypeScript 4.9, MUI 5, TanStack Query 5, Cytoscape (network topology), ECharts + Recharts (analytics), Framer Motion, three.js. Built with Create React App (`react-scripts`).

**Database**
PostgreSQL 15+, 117 migrations under `vulnerability-manager/migrations/`. Heavy use of `JSONB`, triggers (e.g. `network_devices.assigned_at`), and GIN indexes (e.g. team/user `skills`).

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

The discovery worker calls `nmap` with raw socket and OS-detection flags. Two options:

- **`sudo NOPASSWD` (default)** — drop a sudoers fragment so the service can call `nmap` and `arp-scan` without a password:

  ```
  # /etc/sudoers.d/sentinelcore-discovery
  sentinelcore ALL=(root) NOPASSWD: /usr/bin/nmap, /usr/sbin/arp-scan
  ```

  Replace `sentinelcore` with whichever user runs the systemd service.

- **File capabilities** — `sudo setcap cap_net_raw,cap_net_admin=eip /usr/bin/nmap`. This works on some kernels and silently fails on hardened ones; sudo is the boring reliable path.

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
│   │   ├── api/                        # Route definitions (186+ endpoints)
│   │   ├── handlers/                   # Request handlers
│   │   ├── network/                    # Discovery scanner + topology
│   │   ├── scanners/                   # 10 third-party importers
│   │   ├── workers/                    # 9 background tokio workers
│   │   ├── notifications/              # Email/Slack/Telegram/Teams/...
│   │   └── middleware/                 # CSRF, RBAC, rate limit
│   ├── migrations/                     # 117 SQL migrations
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
├── docs/
│   └── NetworkTopology_restyle/        # Design system + UI kit for the topology page
│
├── scripts/                            # Deployment + maintenance scripts
└── packer/                             # VM image build (optional)
```

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

```bash
cd /opt/sentinelcore
git pull origin main

cd vulnerability-manager
sqlx migrate run
SQLX_OFFLINE=true cargo build --release

cd ../vulnerability-manager-frontend
npm install
npm run build

sudo systemctl restart sentinelcore
```

---

## Security

| Layer | What we do |
|-------|-----------|
| **Transport** | TLS terminated at Nginx + HSTS header (`max-age=31536000; includeSubDomains; preload`). |
| **Auth** | JWT in `httpOnly` cookie + CSRF token on POST/PUT/DELETE/PATCH. |
| **Passwords** | Argon2id. |
| **2FA** | TOTP (RFC 6238). |
| **CSP** | Strict default-src `'self'`; configurable per deployment. |
| **Rate limiting** | Per-IP token bucket; per-user is on the roadmap. |
| **SSRF / path injection** | All file paths canonicalized and verified to stay under their canonical base. Outbound HTTP targets validated by host. |
| **Audit log** | Every state-changing action writes an audit entry tied to the user. |

If you spot something, please **don't** open a public issue. Email `security@dognet.tech` instead.

---

## Roadmap

**Shipped in 1.0.1**

- Network Topology restyle on the SentinelCore Design System.
- Configurable nmap discovery with live scan progress.
- File logging + retention worker.
- Single source of truth for device ↔ vulnerability linkage.
- Inline pencil-per-card editing on the device detail page.
- CSRF middleware self-heal across restarts.

**In flight on `develop/v1.0.1`**

- Phase C: skill-based auto-assignment with "add skill" alert in the assignment dialog.
- Container scanning (Trivy / Grype) — importers already in tree, wiring up next.

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

1. Branch off `develop/v1.0.1`, not `main`. `main` only takes curated merges.
2. If you touch a sqlx query, commit the regenerated `.sqlx/` cache in the same PR.

---

## License

MIT — see [LICENSE](LICENSE).

---

<div align="center">

Built by **[Dognet Technologies](https://github.com/Dognet-Technologies)** · [dognet.tech](https://dognet.tech)

If SentinelCore helps your team sleep at night, a GitHub star is the quietest way to say thanks.

</div>
