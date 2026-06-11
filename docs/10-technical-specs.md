# 10 — Technical Specifications

## Stack

| Layer | Technology |
|---|---|
| Backend language | Rust (edition 2021, toolchain 1.75+) |
| Web framework | Axum 0.6 (Tokio, Tower, tower-http, tower-cookies) |
| Database access | SQLx 0.8 (Postgres, compile-time checked queries, offline metadata in `.sqlx/`) |
| Database | PostgreSQL 15+ (JSONB, INET, triggers, plpgsql functions) |
| AuthN | `jsonwebtoken` 10 (aws_lc_rs backend), Argon2 (argon2 0.5), TOTP (`totp-lite`) |
| Crypto | `aes-gcm` (plugin secrets), `sha2` (token hashing, key derivation) |
| HTTP client | reqwest 0.11 (NVD, EPSS, Slack, Telegram, JIRA) |
| Email | lettre 0.11 (SMTP, tokio + native-tls) |
| Exports | quick-xml, csv, printpdf, serde_json |
| Frontend | React 18, TypeScript 4.9, MUI 5, TanStack Query 5, React Router 6, Cytoscape/react-flow, ECharts/Recharts/Chart.js/Plotly, xterm.js, react-scripts (CRA), Playwright |

## Runtime requirements

- Linux host (single-node). The packaged-VM path lives in `packer/`.
- PostgreSQL 15+ reachable via TCP or Unix socket.
- `nmap` installed; a `sudo NOPASSWD` rule for the nmap wrapper enables privileged scan types without running the service as root.
- Optional: reachable GVM/OpenVAS with `gvm-cli` (gvm-tools 26.x) for the direct connector.
- Writable log directory (default `/var/log/sentinelsuite/sentinelcore/`); if creation fails the service falls back to journal-only logging with a warning.
- Default ports: backend `8080`, frontend dev server `3000` (proxied to the API).

## Configuration

Sources, in order: YAML file (`config/default.yaml`, with `config/production.yaml` for production) + `.env` / environment variables (loaded before tracing init).

```yaml
server:
  host: "0.0.0.0"
  port: 8080

database:
  url: "postgresql:///vulnerability_manager?user=...&host=/var/run/postgresql"
  max_connections: 30
  connection_timeout_seconds: 10
  idle_timeout_seconds: 600
  max_lifetime_seconds: 1800

auth:
  secret_key: "<JWT signing secret — set per installation>"
  token_duration_hours: 24
  password_policy:
    min_length: 8
    max_length: 128
    require_uppercase: true
    require_lowercase: true
    require_numbers: true
    require_special_chars: true
    prevent_common_passwords: true

plugins:
  directory: "./plugins"
  enabled: false

network:
  interface: "<scan interface>"
  default_scan_timeout: 500   # ms
  max_scan_workers: 50
```

Environment variables of note:

| Variable | Effect |
|---|---|
| `LOGGING_LEVEL` (or `RUST_LOG`) | Tracing filter (default `warn`) |
| `LOGGING_DESTINATION` | Log file path (default `/var/log/sentinelsuite/sentinelcore/app.log`) |
| `DATABASE_URL` | Used by SQLx tooling (`cargo sqlx prepare`) |

Settings managed at runtime from the UI (persisted in `system_settings`): network discovery scheduler, auto-rescan profile, logging level/destination/retention (level/destination need a service restart; retention is read live), assignment policy.

The security middleware (CORS origin whitelist, security headers, CSRF, rate limit parameters) is configured under `config.security.*` in the YAML.

## Security controls

| Control | Implementation |
|---|---|
| Password storage | Argon2id with per-password salt |
| Password policy | Length + character classes + common-password rejection, validated server-side |
| Sessions | JWT (HS256) in `httpOnly` cookie; `Bearer` fallback; `jti` links token to a revocable session row |
| CSRF | Double-submit token middleware with server-side store, cleanup task, restart self-heal |
| 2FA | TOTP (SHA-1, RFC 6238) with QR provisioning |
| Transport headers | HSTS, CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy via middleware |
| CORS | Configurable origin whitelist; permissive only in development |
| Rate limiting | Configurable (requests/min + burst); enabled per config |
| Upload safety | MIME sniffing via `infer` for avatar/plugin uploads; size limits |
| Secrets at rest | GMP credentials AES-GCM encrypted (SHA-256-derived key); reset tokens stored hashed |
| SQL injection | SQLx parameterized queries exclusively (compile-time checked) |
| Path traversal | Canonicalization + containment checks on plugin directory scans |
| Audit | `audit_logs` with actor/action/entity/metadata; security events logged without sensitive payloads |
| Account protection | Failed-attempt lockout, admin lock/unlock, session revocation, IP whitelist |

## Logging

- `tracing` with two layers: journald/stdout and an optional non-blocking rolling file appender.
- Level and destination from env or Settings UI (restart to apply); retention (age/size, gzip rotation) enforced live by the log-retention worker.

## Build & development

```bash
# Backend
cd vulnerability-manager
cargo build                  # debug build
cargo run                    # starts API on :8080
cargo test                   # unit tests (scoring engine, etc.)
cargo sqlx prepare           # regenerate .sqlx/ after query changes (needs DATABASE_URL)

# Frontend
cd vulnerability-manager-frontend
npm install
npm start                    # dev server on :3000, proxies /api to :8080
npm run build                # production bundle
npx playwright test          # E2E tests
```

Database setup: create the database/user, then apply `migrations/*.sql` in order (the `init-vuln-db` crate assists bootstrap). The automatic `sqlx::migrate!` runner is intentionally disabled in `main.rs`; do not run blind `sqlx migrate run` against an existing instance without checking migration tracking state first.

## Known limits (v1.0.1)

- Single-process, single-host; no HA or horizontal scaling.
- No multi-tenancy.
- Rate-limiter layer is constructed but not yet attached to the router (middleware wiring TODO in `src/api/mod.rs`).
- Notification delivery limited to email/Slack/Telegram.
- Plugin runtime: in-memory registration only; no dynamic native loading or sandboxing yet.
- Local authentication only (no LDAP/SAML/OIDC).
