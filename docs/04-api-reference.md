# 04 — API Reference

REST API over JSON. Base path: `/api`. 188 routes, defined in `vulnerability-manager/src/api/mod.rs`.

## Authentication

| Mechanism | Use |
|---|---|
| JWT in `httpOnly` cookie | Browser sessions (preferred; set on login) |
| `Authorization: Bearer <jwt>` | API clients (fallback) |
| CSRF token | Required on state-changing requests for cookie sessions |

Access levels used below:

- **Public** — no authentication.
- **Auth** — any authenticated user (`require_auth`).
- **Admin** — authenticated user with role `admin` (`require_auth` + `require_admin`).

Errors use standard HTTP status codes (`401` unauthenticated, `403` insufficient role, `404`, `422` validation, `5xx`). Health endpoints return structured JSON status.

## Auth & account recovery

| Method | Path | Access | Description |
|---|---|---|---|
| POST | `/api/auth/register` | Public | Register a new account |
| POST | `/api/auth/login` | Public | Login (username/password + optional TOTP code) |
| POST | `/api/auth/logout` | Auth | Invalidate session |
| POST | `/api/auth/refresh` | Auth | Refresh JWT |
| POST | `/api/auth/forgot-password` | Public | Start legacy forgot-password flow |
| POST | `/api/auth/verify-email` | Public | Confirm email verification token |
| POST | `/api/auth/resend-verification` | Public | Resend verification email |
| POST | `/api/auth/password-reset/initiate` | Public | Initiate password reset (token email) |
| POST | `/api/auth/password-reset/confirm` | Public | Confirm reset with token + new password |
| GET | `/api/auth/password-reset/:token/status` | Public | Check reset token validity |

## Health

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/health` | Public | Liveness + DB connectivity check |
| GET | `/api/ready` | Public | Readiness probe (DB query) |

## Current user (`/users/me`)

| Method | Path | Access | Description |
|---|---|---|---|
| GET / PUT | `/api/users/me` | Auth | Read / update own profile |
| PUT | `/api/users/me/password` | Auth | Change password |
| POST / DELETE | `/api/users/me/avatar` | Auth | Upload / remove avatar |
| GET | `/api/users/me/sessions` | Auth | List own sessions |
| DELETE | `/api/users/me/sessions/:id` | Auth | Revoke a session |
| POST | `/api/users/me/2fa/enable` | Auth | Begin TOTP enrollment (secret + QR) |
| POST | `/api/users/me/2fa/verify` | Auth | Verify TOTP code, activate 2FA |
| POST | `/api/users/me/2fa/disable` | Auth | Disable 2FA |
| GET / PUT | `/api/users/me/security` | Auth | Security settings |
| GET / PUT | `/api/users/me/notifications` | Auth | Notification preferences |
| GET | `/api/users/me/reputation` | Auth | Reputation events |
| GET / POST | `/api/users/me/api-keys` | Auth | List / create personal API keys |
| DELETE | `/api/users/me/api-keys/:key_id` | Auth | Revoke API key |

## User management (admin)

| Method | Path | Access | Description |
|---|---|---|---|
| GET / POST | `/api/users` | Admin | List / create users |
| GET / PUT / DELETE | `/api/users/:id` | Admin | Read / update / soft-delete user |
| POST | `/api/users/:id/lock` · `/unlock` | Admin | Lock / unlock account |
| GET | `/api/users/:id/sessions` | Admin | List user sessions |
| POST | `/api/users/:id/sessions/revoke-all` | Admin | Revoke all sessions |

## Vulnerabilities

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/vulnerabilities` | Auth | List with filtering/pagination (status, severity, tier, EPSS, search) |
| GET | `/api/vulnerabilities/:id` | Auth | Detail |
| GET | `/api/vulnerabilities/by-cve/:cve_id` | Auth | Lookup by CVE |
| GET | `/api/vulnerabilities/my-assigned` | Auth | Findings assigned to the caller |
| POST | `/api/vulnerabilities` | Admin | Create manually |
| PUT / DELETE | `/api/vulnerabilities/:id` | Admin | Update / soft-delete |
| POST | `/api/vulnerabilities/:id/assign` | Admin | Assign to team |
| POST | `/api/vulnerabilities/:id/assign-user` | Admin | Assign to user |
| POST | `/api/vulnerabilities/bulk-assign` | Admin | Bulk assignment |
| POST | `/api/vulnerabilities/bulk-update` | Admin | Bulk severity/CVSS/status edit |
| POST | `/api/vulnerabilities/merge` | Admin | Merge duplicates |
| GET | `/api/vulnerabilities/:id/sources` | Admin | Per-scanner source records |

## Assets

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/assets` | Auth | List |
| GET | `/api/assets/:id` · `/:id/details` | Auth | Detail / extended detail |
| POST | `/api/assets` | Admin | Create |
| PUT / DELETE | `/api/assets/:id` | Admin | Update / soft-delete |

## Network discovery & topology

| Method | Path | Access | Description |
|---|---|---|---|
| POST | `/api/network/scan` | Auth | Start nmap discovery scan |
| GET | `/api/network/scan/:scan_id` | Auth | Scan status/progress |
| GET | `/api/network/topology` | Auth | Topology graph |
| GET | `/api/network/topology-with-vulnerabilities` | Auth | Topology + vuln counts |
| GET / PUT | `/api/network/devices/:device_id` | Auth | Device detail / update |
| GET | `/api/network/devices/:device_id/vulnerabilities` | Auth | Device findings |
| GET | `/api/network/devices/:device_id/trends` | Auth | Daily metric trends |
| GET | `/api/network/devices/:device_id/ports` | Auth | Open ports + services |
| POST | `/api/network/devices/bulk-assign` | Auth | Bulk device assignment |
| POST | `/api/network/remediation` | Auth | Execute remediation action |

## Scanner imports

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/scanners` | Auth | Available importer metadata |
| GET | `/api/scanner-imports` | Auth | Import history |
| POST | `/api/scanners/import` | Admin | Import scan from JSON body |
| POST | `/api/scanners/import/:scanner/:format` | Admin | Import uploaded scan file |

## Teams & workload

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/teams` · `/api/teams/:id` · `/:id/members` | Auth | Team views |
| GET | `/api/skills-catalog` | Auth | Skills for matching |
| POST | `/api/teams` | Admin | Create team |
| PUT / DELETE | `/api/teams/:id` | Admin | Update / delete team |
| POST | `/api/teams/:id/members` · `/:id/assign-user` | Admin | Add member / assign user |
| PUT | `/api/teams/:team_id/members/:member_id/role` | Admin | Change member role |
| DELETE | `/api/teams/:team_id/members/:user_id` | Admin | Remove member |
| GET | `/api/workload/me` | Auth | Own workload |
| GET | `/api/workload/users` · `/users/:id` | Admin | Per-user workload |
| GET | `/api/workload/teams` · `/teams/:id` | Admin | Per-team workload |

## Assignment rules & policy

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/assignment-rules` · `/:id` | Auth | View rules |
| POST | `/api/assignment-rules` | Admin | Create rule |
| PUT / DELETE | `/api/assignment-rules/:id` | Admin | Update / delete rule |
| POST | `/api/assignment-rules/test` | Admin | Dry-run a rule |
| GET / PUT | `/api/admin/assignment-policy` | Admin | Global auto/manual policy |

## Remediation plans

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/remediation-plans` · `/:id` | Auth | View plans |
| POST | `/api/remediation-plans` | Admin | Create plan |
| PUT / DELETE | `/api/remediation-plans/:id` | Admin | Update / delete plan |

## Risk scoring & SLA

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/risk/statistics` | Auth | Risk distribution stats |
| GET | `/api/risk/sla/breaches` | Auth | Current SLA breaches |
| POST | `/api/risk/vulnerabilities/:id/calculate` | Admin | Recalculate one score |
| POST | `/api/risk/sla/mark-breaches` | Admin | Force breach marking |

## Risk acceptance

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/risk-acceptance` · `/:id` | Auth | View acceptances |
| POST | `/api/risk-acceptance` | Admin | Create request |
| POST | `/api/risk-acceptance/:id/approve` · `/reject` · `/renew` · `/review` | Admin | Lifecycle actions |

## Resolution scoring

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/resolutions/my-stats` | Auth | Own resolution stats |
| GET | `/api/resolutions/leaderboard` | Auth | User leaderboard |
| GET | `/api/resolutions/teams/leaderboard` | Auth | Team leaderboard |
| GET | `/api/resolutions/teams/:team_id/stats` | Auth | Team stats |
| POST | `/api/resolutions` | Admin | Record a resolution |
| POST | `/api/resolutions/:id/verify` | Admin | Verify a resolution |

## Comments & mentions

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/comments/entity/:entity_type/:entity_id` | Auth | Thread for an entity |
| POST | `/api/comments` | Auth | Create comment |
| PUT / DELETE | `/api/comments/:comment_id` | Auth | Edit / delete own comment |
| GET | `/api/mentions/me` | Auth | Mentions feed |

## Notifications

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/notification-rules` · `/:id` | Auth | View rules |
| GET | `/api/notification-channels` | Auth | View channels |
| POST | `/api/notification-rules` | Admin | Create rule |
| PUT / DELETE | `/api/notification-rules/:id` | Admin | Update / delete rule |
| POST | `/api/notification-rules/:id/test` | Admin | Test-fire rule |
| POST | `/api/notification-channels` | Admin | Create channel |
| DELETE | `/api/notification-channels/:id` | Admin | Delete channel |

## Reports & compliance

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/reports` · `/:id` | Auth | List / detail |
| GET | `/api/reports/:id/download` | Auth | Download artifact |
| POST | `/api/reports/:id/generate` | Auth | Queue generation |
| POST | `/api/reports/:id/send` | Auth | Email report |
| POST | `/api/reports/:id/duplicate` | Auth | Duplicate definition |
| POST | `/api/reports/generate-management` | Auth | Management report |
| POST | `/api/reports` | Admin | Create definition |
| PUT / DELETE | `/api/reports/:id` | Admin | Update / delete |
| POST | `/api/compliance/generate` | Admin | Generate compliance report |
| GET | `/api/compliance/reports` | Admin | Compliance report history |

## Dashboard

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/dashboard/stats` | Auth | Aggregate stats |
| GET | `/api/dashboard/network-topology` | Auth | Topology for dashboard |

## Plugins

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/plugins` · `/:id` | Auth | List / detail |
| POST | `/api/plugins` | Admin | Install (register) |
| PUT / DELETE | `/api/plugins/:id` | Admin | Update config / uninstall |
| POST | `/api/plugins/:id/toggle` | Admin | Enable/disable |
| POST | `/api/plugins/upload` | Admin | Upload plugin package |
| POST | `/api/plugins/scan` | Admin | Rescan plugin directory |
| POST | `/api/plugins/:id/execute` | Admin | Execute plugin action |
| GET / PUT | `/api/plugins/openvas/config` | Admin | OpenVAS connector config |
| POST | `/api/plugins/openvas/test` | Admin | Test GMP connection |

## JIRA integration

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/api/jira/configurations` · `/:id` | Auth | View configurations |
| GET | `/api/jira/tickets` | Auth | Linked tickets |
| POST | `/api/jira/configurations` | Admin | Create configuration |
| PUT / DELETE | `/api/jira/configurations/:id` | Admin | Update / delete |
| POST | `/api/jira/test-connection` | Admin | Test credentials |
| POST | `/api/jira/tickets` | Admin | Create ticket from finding |
| POST | `/api/jira/tickets/:id/sync` | Admin | Force sync |

## SOAR webhooks

| Method | Path | Access | Description |
|---|---|---|---|
| GET / POST | `/api/soar/webhooks` | Admin | List / create webhooks |
| DELETE | `/api/soar/webhooks/:id` | Admin | Delete webhook |
| POST | `/api/soar/webhooks/:id/trigger` | Admin | Manual trigger |

## Security & audit (admin)

| Method | Path | Access | Description |
|---|---|---|---|
| GET / POST | `/api/security/ip-whitelist` | Admin | List / add whitelist entries |
| DELETE | `/api/security/ip-whitelist/:id` | Admin | Remove entry |
| GET | `/api/security/permissions/user/:user_id` | Admin | User permissions |
| POST | `/api/security/permissions` | Admin | Grant permission |
| DELETE | `/api/security/permissions/:id` | Admin | Revoke permission |
| GET / POST | `/api/audit/logs` | Admin | Query / write audit entries |
| GET | `/api/audit/logs/:id` | Admin | Single entry |
| GET | `/api/audit/stats` | Admin | Audit statistics |

## System administration

| Method | Path | Access | Description |
|---|---|---|---|
| GET / PUT | `/api/admin/network-discovery-settings` | Admin | Discovery scheduler config |
| GET / PUT | `/api/admin/logging-settings` | Admin | Log level/destination/retention |
| GET | `/api/admin/db/status` | Admin | DB / soft-delete status |
| POST | `/api/admin/db/purge` | Admin | Hard-delete purge |

## Static

| Method | Path | Access | Description |
|---|---|---|---|
| GET | `/uploads/*` | Public | Served upload files (avatars) |
