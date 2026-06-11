# 02 — Architecture

## System components

```
                    ┌─────────────────────────────┐
                    │   React 18 SPA (MUI 5)      │
                    │   vulnerability-manager-    │
                    │   frontend  (~32k LOC TS)   │
                    └──────────────┬──────────────┘
                                   │ REST /api/* (JSON)
                                   │ JWT httpOnly cookie + CSRF token
                    ┌──────────────▼──────────────┐
                    │   Rust backend (Axum 0.6)   │
                    │   vulnerability-manager     │
                    │                             │
                    │  ┌───────────────────────┐  │
                    │  │ Middleware stack      │  │
                    │  │ cookies→CORS→headers→ │  │
                    │  │ CSRF→auth→role        │  │
                    │  └───────────────────────┘  │
                    │  ┌───────────┐ ┌──────────┐ │
                    │  │ Handlers  │ │ 12 BG    │ │
                    │  │ (24 mods) │ │ workers  │ │
                    │  └───────────┘ └──────────┘ │
                    └──────┬──────────────┬───────┘
                           │ SQLx (compile-time     │ outbound
                           │ checked queries)       │
                ┌──────────▼─────────┐   ┌──────────▼─────────────────┐
                │  PostgreSQL 15+    │   │ External services          │
                │  ~69 tables        │   │ NVD API · EPSS (FIRST.org) │
                │  triggers + fns    │   │ JIRA · SMTP · Slack ·      │
                │  JSONB conditions  │   │ Telegram · GVM/OpenVAS ·   │
                └────────────────────┘   │ SOAR webhooks · nmap (local)│
                                         └────────────────────────────┘
```

### Backend (`vulnerability-manager/`)

Single Rust binary (`vulnerability-manager`), Tokio async runtime. Internal module layout:

| Module | Responsibility |
|---|---|
| `src/api/` | Router assembly: public / protected / admin route groups, middleware stack |
| `src/handlers/` | 24 handler modules — one per functional area (vulnerability, asset, team, user, report, plugin, jira_integration, …) |
| `src/auth/` | JWT issue/verify, Argon2 password hashing, password policy, `require_auth` / `require_admin` middleware |
| `src/middleware/` | CORS, CSRF (token store + cleanup task), JWT cookie handling, security headers, rate limiter |
| `src/models/` | Typed domain models mapped to DB rows (SQLx `FromRow`) |
| `src/db/` | Pool helpers |
| `src/scanners/` | Scanner importer plugins (trait `ScannerPlugin` + registry), 10 parsers |
| `src/scoring/` | Risk scoring engine: `risk_calculator`, `business_impact`, `asset_exposure`, `exploit_intelligence` |
| `src/network/` | nmap-based discovery, topology, device handlers, remediation executor, system verification |
| `src/workers/` | 11 periodic background workers (see [09](09-background-workers.md)) |
| `src/notifications/` | Delivery channels: email (lettre/SMTP), Slack webhook, Telegram bot |
| `src/integrations/` | OpenVAS/GMP client + AES-GCM credential crypto |
| `src/plugins/` | Plugin manager (registration, enable/disable, execute) |
| `src/export/` | Report serializers: CSV, JSON, XML, PDF (printpdf) |
| `src/audit.rs` | Audit trail writer |

### Frontend (`vulnerability-manager-frontend/`)

React 18 + TypeScript SPA, Material-UI (MUI 5) component system, TanStack React Query for server state, React Router 6, Cytoscape + react-flow for the topology graph, ECharts/Recharts/Chart.js/Plotly for dashboards, xterm.js for the live scan terminal. Build tooling is react-scripts (CRA); Playwright for E2E tests.

Main pages: Dashboard, ExecutiveDashboard, NetworkDashboard (topology), NetworkDiscovery, Vulnerabilities + VulnerabilityDetailPage, MyVulnerabilities, Assets, Hosts, DeviceDetailsPage, RemediationPlans + RemediationPlanPage, Reports/NewReport/ReportHistory/ReportView, ScannerImports, Teams, Users, Profile, Settings, Plugins, JiraIntegration, NotificationRules, WorkloadDashboard, TechnicalHeatmap, Login.

### Database

PostgreSQL 15+. Schema is managed by 76 ordered SQL migrations (`migrations/`). Business logic lives in the database where it must be transactional and event-driven:

- **Triggers**: risk score recalculation on vulnerability insert/update, `@mention` extraction on comments, device→asset sync, timeline entries.
- **Functions**: `mark_sla_breaches()`, JSONB condition evaluation for notification/assignment rules.
- **JSONB columns**: rule conditions, plugin config, device metadata — indexed with GIN where queried.
- **INET / CIDR native types** for addresses, `TIMESTAMPTZ` everywhere, soft delete (`deleted_at`) with cascading semantics.

## Request flow

The middleware chain, outermost first (`src/api/mod.rs`):

```
request
  → CookieManager            (parse cookies)
  → CORS                     (configurable origin whitelist)
  → security headers         (HSTS, CSP, X-Frame-Options, …)
  → CSRF cookie injection    (issue token)
  → CSRF validation          (state-changing requests)
  → route group:
      public     (no auth: login, register, password reset, health)
      protected  (require_auth: JWT from cookie or Bearer header)
      admin      (require_auth + require_admin: role == admin)
  → handler → SQLx → PostgreSQL
```

Authentication accepts the JWT from the httpOnly cookie first (browser flow) and falls back to an `Authorization: Bearer` header (API clients). Claims (`sub`, `role`, `exp`, `iat`, `jti`) are injected into request extensions; role checks read claims only.

## Vulnerability lifecycle (primary data flow)

```
1. INGEST     nmap discovery │ scanner file upload │ OpenVAS poller
2. PARSE      scanner plugin → ParsedVulnerability (normalized severity, CVE/CWE, host, port)
3. DEDUPE     fingerprint on CVE + host + port (open findings only); reopen tracking
4. LINK       device → asset (assets.network_device_id) → vulnerability
5. ENRICH     NVD worker (CVSS vector, CWE, references) · EPSS worker (daily scores)
6. SCORE      DB trigger: composite risk score + tier + SLA deadline (see 03-features)
7. ASSIGN     assignment policy (auto/manual) → rules engine → team/user
8. NOTIFY     notification rules (conditions, priority, throttle, quiet hours) → email/Slack/Telegram
9. TICKET     JIRA auto-ticket rules → ticket creation → bi-directional status sync
10. TRACK     SLA checker worker → breach marking → escalation notifications
11. REMEDIATE remediation plan → executor / manual fix → post-remediation check
12. VERIFY    re-scan; failed checks surface on the vulnerability detail page
13. CLOSE     resolution recorded → resolution scoring → leaderboards → audit trail
```

## Process model

One OS process. At startup `main.rs`:

1. Loads `.env` + YAML config (`config/default.yaml`, overridable per environment).
2. Initializes tracing (journal + optional rolling file with retention worker).
3. Connects the SQLx pool (max connections, acquire/idle/lifetime timeouts from config).
4. Verifies network scanning prerequisites (nmap availability/privileges) — degrades gracefully with a warning.
5. Spawns the remediation executor and the 11 periodic workers as Tokio tasks.
6. Builds shared `AppState` (pool, auth, config, CSRF store) and serves the Axum router.

Workers and HTTP handlers share the same connection pool and communicate exclusively through PostgreSQL (no message broker).
