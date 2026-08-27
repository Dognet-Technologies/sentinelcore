---
name: sentinelcore-patterns
description: Coding and workflow patterns extracted from the sentinelcore repo's git history (Rust/axum backend + React/TS frontend). Use when writing commits, migrations, or wiring a backend change through to the frontend/docs in this repo.
version: 1.0.0
source: local-git-analysis
analyzed_commits: 199
---

# SentinelCore Patterns

Extracted from the last 199 commits on `develop/v1.2.0`. These are observed conventions, not aspirational ones — follow them so changes look native to the codebase.

## Commit Conventions

Conventional Commits, in Italian for the body/scope content, English type keywords:

```
<type>(<scope>): <description in Italian>
```

Type distribution (199 commits, 90% conventional):
- `fix:` 73 — by far the most common; this is a bug-fix-driven codebase
- `feat:` 68
- `chore:` 14 (almost entirely `chore(sqlx)`, see below)
- `docs:` 12
- `refactor:` 6
- `ci:` 2, `style:` 1, `security:` 1, `revert:` 1

Scopes are the touched feature/module, not the file: `network`, `reports`, `vuln`, `remediation`, `network-topology`, `my-activities`, `sqlx`, `topology`, `settings`, `install`, `deps`, `vulnerabilities`, `profile`, `packaging`, `db`, `device-types`, `notifications`...

Description style: short, factual, often names the concrete symptom or root cause rather than the fix mechanism, e.g.:
- `fix(vulnerabilities): discovered_at NOT NULL senza default rompeva ogni creazione manuale`
- `fix(reports): mostra risk score/tier invece del CVSS grezzo`
- `fix(plugins): nasconde smtp_email dalla pagina Plugin`

## The `chore(sqlx)` Ritual

**Any commit that touches a `sqlx::query!`/`query_as!` macro (adds a column to a struct, changes a SELECT, adds a query) must be followed by a `chore(sqlx): rigenera query cache dopo <cosa>` commit** that regenerates `.sqlx/` offline query metadata. This shows up after nearly every backend feature/fix in the log:

```
90dcceb fix(ui): versione nel menu laterale ferma a v1.0.1, ora v1.2.0
ec970a4 chore(sqlx): rigenera query cache dopo i fix su plugin/vulnerability/report
```

Run `cargo sqlx prepare` (or the project's equivalent) and commit the regenerated cache as its own commit, separate from the feature/fix commit, with a message naming what changed.

## Migrations

Sequentially numbered, `NNN_snake_case_description.sql` in `vulnerability-manager/migrations/` (currently up to 152). One migration per commit/feature, named after the feature not the ticket:

```
149_user_personal_slack_webhook.sql
150_user_api_keys_scope.sql
151_smtp_plugin.sql
152_notification_preferences.sql
```

Since 2026-08 every migration must be idempotent (`ADD COLUMN IF NOT EXISTS`, `IF NOT EXISTS`, `ON CONFLICT`) — required for the in-place upgrade manager (`packaging/upgrade.sh`) to be safely re-run. See [[sentinelcore-migrations-idempotent]].

Migrations carry a comment block explaining the *why* and any default-value reasoning (e.g. why a new boolean defaults to `false` for existing users vs `true`) — not just the DDL. Follow this; it's load-bearing documentation for anyone reading the migration later.

## Architecture / Hot Files

Most-churned files (200-commit window) — these are the natural extension points and the ones most likely to already have the pattern you need:

Backend (`vulnerability-manager/src/`):
- `api/mod.rs` (25) — route registration
- `handlers/vulnerability.rs` (22) — the busiest handler; vuln CRUD, assignment, status transitions
- `network/models.rs` (16), `network/handler.rs` (13), `network/scanner.rs` (9)
- `handlers/user.rs` (11), `main.rs` (10), `handlers/scanner_import.rs` (10), `handlers/remediation_plan.rs` (10)
- `handlers/report.rs` (9), `handlers/management_report.rs` (8), `models/vulnerability.rs` (7), `handlers/team.rs` (7)

Frontend (`vulnerability-manager-frontend/src/`):
- `pages/Settings.tsx` (16) — every new per-user preference or admin toggle lands here
- `components/NetworkTopology.tsx` (14)
- `pages/Vulnerabilities.tsx` (12), `api/network.ts` (12)
- `pages/MyVulnerabilities.tsx` (10), `pages/Profile.tsx` (9), `pages/RemediationPlanPage.tsx` (8), `pages/NetworkDashboard.tsx` (8)

## Cross-Cutting Feature Workflow

A backend feature/fix in this repo routinely fans out across the same set of layers in the same commit or commit pair — evident from the notifications feature and prior rounds this session:

1. Migration (`migrations/NNN_*.sql`, idempotent)
2. Backend model/struct field(s) + handler logic (often touching `handlers/vulnerability.rs` and/or `handlers/user.rs`)
3. `api/settings.ts` or equivalent frontend API type mirrored 1:1 with the backend struct
4. `pages/Settings.tsx` (or the relevant page) UI wiring, often role-gated (`isAdmin`/`isTeamLeaderOrAdmin` booleans gating which sections render)
5. i18n: both `it/*.json` and `en/*.json` updated together, same keys
6. `chore(sqlx)` cache regen commit if any query shape changed
7. User-guide doc update under `docs/user-guide/NN-*.md` (Italian) when the feature is user-facing
8. Deploy: `packaging/build-release.sh <version>` → scp tarball → `upgrade.sh` on the VM → verify (`systemctl is-active`, `/api/health`, migration count, frontend bundle hash)

Enum-like fields (e.g. device_type) additionally require frontend union type + Rust enum + Postgres enum, kept in sync — see the `[project]` instinct on enum changes.

## Docs Are Two Separate Trees

- `docs/*.md` (numbered 01-11) — English, technical/architecture reference for developers.
- `docs/user-guide/*.md` (numbered 00-10) — Italian, end-user manual, built to PDF via `docs/user-guide/build-pdf.sh`.

A user-facing feature typically only needs the second tree updated; the first tree is for architecture-level changes (new subsystem, new data model, new plugin type).

## Testing

Thin test coverage relative to churn: 18 Rust files have `#[cfg(test)]`, only 3 frontend `.test.ts(x)` files exist. Don't assume TDD is the house style here — this repo prioritizes shipping fixes fast with `cargo build`/`tsc --noEmit`/manual browser verification over unit-test-first development. When adding tests, match existing nearby test style rather than introducing a new framework or pattern.

## Related Memory

- [[sentinelcore-vm-deploy]] — exact VM deploy command sequence
- [[sentinelcore-migrations-idempotent]] — idempotency requirement detail
- [[vulnerability-model-fromrow-gotcha]] — sqlx FromRow gotcha when adding fields to `Vulnerability`
