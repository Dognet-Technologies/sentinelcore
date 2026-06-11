# 05 — Roles & Permissions

## Role model

Three roles, stored as the PostgreSQL enum `user_role` and embedded in the JWT (`role` claim). Defined in `src/models/user.rs`:

| Role | Value | Intent |
|---|---|---|
| Administrator | `admin` | Full platform control: user/team management, all write operations on shared entities, integrations, security, settings |
| Team Leader | `team_leader` | A team-scoped coordinator role; recognized by middleware (`require_team_leader` accepts `admin` or `team_leader`) |
| User | `user` | Analyst/operator: works assigned findings, comments, generates reports, views shared data |

## How authorization is enforced

Authorization is route-group based (`src/api/mod.rs` + `src/auth/mod.rs`):

1. **`require_auth` middleware** — extracts the JWT (httpOnly cookie first, `Authorization: Bearer` fallback), validates signature and expiry, and injects `Claims { sub, role, exp, iat, jti }` into the request.
2. **`require_admin` middleware** — layered on the admin route group; rejects with `403` unless `role == admin`.
3. **`require_team_leader` middleware** — available for team-scoped routes; passes `admin` and `team_leader`.
4. **Handler-level checks** — ownership rules inside handlers (e.g. a user can edit/delete only their own comments, revoke only their own sessions, see their own workload).

There is no per-object ACL: visibility of shared entities (vulnerabilities, assets, teams, reports, topology) is platform-wide for authenticated users; mutation is concentrated on `admin`.

## Capability matrix

| Capability | user | team_leader | admin |
|---|:--:|:--:|:--:|
| View vulnerabilities, assets, topology, teams, reports, plans, rules | ✅ | ✅ | ✅ |
| Run network discovery scans, edit devices, bulk-assign devices | ✅ | ✅ | ✅ |
| Comment, mention, edit own comments | ✅ | ✅ | ✅ |
| Generate / download / email reports | ✅ | ✅ | ✅ |
| Manage own profile, 2FA, API keys, sessions | ✅ | ✅ | ✅ |
| View own workload, resolution stats, leaderboards | ✅ | ✅ | ✅ |
| Create / edit / delete vulnerabilities, bulk operations, merge | ❌ | ❌ | ✅ |
| Assign vulnerabilities (team/user/bulk) | ❌ | ❌ | ✅ |
| Manage assets, teams, team membership | ❌ | ❌ | ✅ |
| Manage users (CRUD, lock, sessions) | ❌ | ❌ | ✅ |
| Manage assignment rules and policy | ❌ | ❌ | ✅ |
| Manage notification rules and channels | ❌ | ❌ | ✅ |
| Import scanner files | ❌ | ❌ | ✅ |
| Manage remediation plans | ❌ | ❌ | ✅ |
| Risk acceptance lifecycle (approve/reject/renew/review) | ❌ | ❌ | ✅ |
| Record / verify resolutions | ❌ | ❌ | ✅ |
| Manage plugins (install, toggle, execute, OpenVAS connector) | ❌ | ❌ | ✅ |
| JIRA configurations, ticket creation, sync | ❌ | ❌ | ✅ |
| SOAR webhooks | ❌ | ❌ | ✅ |
| IP whitelist, granular permissions | ❌ | ❌ | ✅ |
| Audit log access | ❌ | ❌ | ✅ |
| System settings (discovery, logging, assignment policy), DB purge | ❌ | ❌ | ✅ |

Note: `team_leader` currently has the same route-level grants as `user`; its distinct value surfaces in team-scoped flows (team member roles, escalation recipients in notification rules) and in the `require_team_leader` middleware available for future team-scoped routes.

## Team-level roles

Independent of the platform role, each team membership has its own `role` field (`team_members.role`, e.g. member/leader designation within a team), editable by admins via `PUT /api/teams/:team_id/members/:member_id/role`. Assignment rules may filter eligible assignees by this team-member role.

## Granular permissions

Beyond RBAC, the `user_permissions` table (migration 007) supports per-user grants:

- `permission` string, optionally scoped to a `resource_type` / `resource_id`;
- expiry (`expires_at`), activation flag, and full grant/revoke audit (who granted, who revoked, when, why).

Managed via `/api/security/permissions*` (admin). This is an additive mechanism for exceptional grants; route protection remains role-based.

## Account security controls

- Failed-login attempt counter with temporary account lock (`account_locked_until`); manual lock/unlock by admins.
- Optional TOTP 2FA enforced at login when enabled.
- Password policy (length, character classes, common-password rejection) from configuration; password expiration policy (migration 028).
- Email verification flow with skip option for admin-created accounts.
- Sessions tracked per device (IP, user agent) with per-session and revoke-all revocation.
- IP whitelist entries (CIDR) scoped globally, per user, or per team.
