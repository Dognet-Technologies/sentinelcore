# 11 — MCP Contract (cross-product)

Shared contract for the **Model Context Protocol (MCP)** servers embedded in the
Dognet Technologies product suite: **SentinelCore**, **FireDog**, and
**CyberSheppard**. The goal is that a single agent can talk to all three with
**one mental model** — same transport, same auth shape, same tool naming and
response envelope — while each product keeps its own domain-specific tools.

> Status: SentinelCore implements this contract (phase 1 + phase 2). FireDog and
> CyberSheppard sections describe how they **must** implement it; their tool
> catalogs are proposals until built. When code and this doc disagree, the code
> wins.

Related: [04 — API Reference](04-api-reference.md), [05 — Roles &
Permissions](05-roles-and-permissions.md), [08 — Plugin System](08-plugin-system.md).

---

## 1. Architecture decision

**One MCP server per product, embedded natively in that product's backend.**
Not a single external gateway. Rationale: the three products run on different
stacks (SentinelCore = Rust/Axum, FireDog = Python/Django, CyberSheppard =
its own stack), and a native server reuses each product's existing
authentication, RBAC/scope, and data access without a translation layer or a
second source of truth.

The cost — three implementations to keep in sync — is paid down by **this
contract**: transport, auth, protocol surface, naming, and envelope are
identical across products, so only the domain tools differ.

---

## 2. Endpoint & transport

| Item | Convention |
|---|---|
| Endpoint | `POST /api/mcp` (single path, under the product's API base) |
| Protocol | JSON-RPC 2.0 |
| Transport | Streamable HTTP, request→response JSON. SSE / `Mcp-Session-Id` sessions are **optional** and only needed once a product streams or holds server-side session state. Phase-1 read-only servers may omit them. |
| Content type | `application/json` for both request and response |
| Batching | Servers MUST accept a JSON array of requests. Notifications (no `id`) in a batch produce no response; a batch of only notifications returns `202 Accepted` with an empty body. |

### Protocol methods (minimum surface)

Every product's MCP server MUST implement:

| Method | Result |
|---|---|
| `initialize` | `{ protocolVersion, capabilities: { tools: {} }, serverInfo: { name, version } }`. Echo the client's `protocolVersion` if provided, else the server default. |
| `notifications/initialized` | Notification — no response. |
| `ping` | `{}` |
| `tools/list` | `{ tools: [ { name, description, inputSchema } ] }` |
| `tools/call` | See §5. |

`serverInfo.name` convention: `<product>-mcp` (e.g. `sentinelcore-mcp`,
`firedog-mcp`, `cybersheppard-mcp`). `serverInfo.version` = the product's own
package version.

---

## 3. Authentication

**Per-product API key, presented as a Bearer token.** The agent authenticates
with `Authorization: Bearer <api-key>` against the same middleware that
protects the rest of the product's API.

| Rule | Requirement |
|---|---|
| Identity | The API key **impersonates its owning user**. Derived credentials carry the same user id and role, so the product's existing RBAC/scope applies unchanged and audit attributes actions to that user. |
| Storage | API keys are hashed with **SHA-256** (never stored or re-shown in clear). MD5 or unsalted-weak hashes are not acceptable. |
| Key format | Human-visible prefix so keys are identifiable in logs/UI. SentinelCore uses `sk_<48 alphanumerics>`. |
| Lifecycle | Keys are per-user, listable, revocable, and support optional expiry. `last_used_at` is updated on use (best-effort). |
| Scope (phase-2 guardrail) | A key carries its own `read`/`write` scope, independent of the owning user's role. Keys are `read` by default; only an **admin** may create a `write` key (self or, once an admin-provisioning flow exists, for a dedicated service account). Write tools reject any credential that isn't `Some("write")` — a JWT-cookie session (no key scope) or a `read` key both fail closed. SentinelCore implements this as `user_api_keys.scope` + `Claims.mcp_key_scope`. |
| CSRF | The MCP endpoint is exempt from CSRF. This is safe **only because** access is Bearer-only; it MUST NOT rely on an ambient session cookie. |
| Transport security | The endpoint MUST be served over TLS in production. |

Phase-2 (write) tools MUST additionally reject cookie-only auth on the MCP path
and enforce the product's per-action scope before mutating.

---

## 4. Tool naming conventions

Tools are the shared vocabulary. Names are `snake_case`, verb-first, and stable.

| Verb prefix | Meaning | Tier |
|---|---|---|
| `list_<plural>` | Return a filtered, paginated collection | Read (phase 1) |
| `get_<singular>` | Return one entity by id (or a natural key) | Read (phase 1) |
| `search_<plural>` | Free-text / semantic query over a collection | Read (phase 1) |
| `get_<x>_summary` | Aggregated / prioritized rollup | Read (phase 1) |
| `create_<singular>` | Create an entity | Write (phase 2) |
| `update_<singular>` | Mutate an entity | Write (phase 2) |
| `<verb>_<singular>` | Domain action (e.g. `assign_`, `accept_`, `trigger_`) | Write (phase 2) |

Rules:

- A tool that reads MUST NOT mutate. Only phase-2 verbs may change state.
- `description` states what the tool returns **and** which key fields it exposes,
  so the agent can plan without a schema round-trip.
- `inputSchema` is a JSON Schema object with `"additionalProperties": false`.
- Prefer one flexible `list_*` with filters over many narrow tools.

---

## 5. Response envelope

### `tools/call` success

```json
{
  "content": [{ "type": "text", "text": "<JSON payload, pretty-printed>" }],
  "isError": false
}
```

The `text` is the domain payload serialized as JSON. Collections use a
consistent shape:

```json
{ "<plural>": [ ... ], "total": <int>, "limit": <int>, "offset": <int> }
```

Single-entity results use `{ "<singular>": { ... } }`, and a not-found lookup
returns `{ "<singular>": null, "found": false }` (not an error).

### Error semantics

| Situation | How it is returned |
|---|---|
| Unknown method | JSON-RPC error `-32601` (Method not found) |
| Unknown tool / bad arguments / missing required param | JSON-RPC error `-32602` (Invalid params) |
| Malformed JSON-RPC request | JSON-RPC error `-32600` (Invalid request) |
| Tool **execution** failure (DB, downstream) | `tools/call` **result** with `isError: true` and a generic message. The detailed cause is logged server-side, never returned to the client. |

This split is deliberate: protocol/usage mistakes are JSON-RPC errors the agent
can correct; runtime failures are surfaced through `isError` so the agent sees
them as a tool outcome, not a transport fault.

### Pagination & filters

- `limit` (default 50, hard max 200) and `offset` (0-based) on every `list_*`.
- Multi-select filters are passed as comma-separated strings (e.g.
  `"severities": "critical,high"`) to match the products' URL-encoded filter
  parsing. Single-value filters take a scalar.

---

## 6. Capability tiers

| Phase | Scope | Status |
|---|---|---|
| **Phase 1** | Read-only: `list_*`, `get_*`, `search_*`, `*_summary` | SentinelCore: done. FireDog / CyberSheppard: pending. |
| **Phase 2** | Write / actions, gated by per-action RBAC scope | SentinelCore: done. FireDog / CyberSheppard: pending. |

A product MAY ship phase 1 before phase 2. Read tools MUST remain read-only
after phase 2 lands.

---

## 7. Per-product tool catalogs

### 7.1 SentinelCore — vulnerability management (implemented, phase 1)

Server: `sentinelcore-mcp`. Tools reuse the REST layer's shared query functions
(`handlers::vulnerability::query_vulnerability_page / _by_id / _by_cve`) so the
MCP and web surfaces cannot drift. Focus: vulnerabilities and the fields that
feed the risk engine.

| Tool | Input | Returns |
|---|---|---|
| `list_vulnerabilities` | `status`, `severity`, `severities`, `statuses`, `cve_id`, `hostname`, `ip_address`, `assigned_team_id`, `asset_id`, `limit`, `offset` | Vulnerabilities ordered by `risk_score` (engine prioritization), with `cvss_score`, `epss_score`, `in_cisa_kev`, `status`, `severity`, `discovered_at`, `last_resolved_at`, `risk_score`, `risk_tier`. |
| `get_vulnerability` | exactly one of `id` (UUID) or `cve_id` | Full vulnerability detail; `cve_id` returns all host occurrences. |
| `get_risk_summary` | `limit` (top-N, default 10) | `total_active`, `cisa_kev_count`, `avg_risk_score`, `top_by_risk`. |

Visibility in phase 1 mirrors the web API (the `list_vulnerabilities` REST
endpoint is not server-side scope-filtered; see [05 — Roles &
Permissions](05-roles-and-permissions.md)).

**Phase 2 (implemented)** — each write tool calls its REST handler directly
(same axum extractors constructed in-process) so authorization is bit-for-bit
identical to the web API, not a reimplementation:

| Tool | Maps to (REST) | Authorization |
|---|---|---|
| `update_vulnerability_status` | `PUT /api/vulnerabilities/:id` (status/remediation only) | admin: always. Assigned user: only their own vulnerability, status+remediation only. Anyone else: rejected. |
| `assign_vulnerability` | `PUT /api/vulnerabilities/:id` (assigned_team_id/assigned_user_id only) | admin only (the handler rejects these fields from a non-admin, including the assignee). |
| `accept_risk` | `POST /api/risk-acceptance` | admin only — enforced explicitly inside the tool, because the REST route's admin check lives in route-level middleware that MCP dispatch doesn't traverse. |
| `trigger_scan` | `POST /api/network/scan` | any authenticated identity (REST endpoint itself has no role check). |

All four additionally require the calling API key's own scope to be
`write` (see §3) — a guardrail independent of the impersonated user's role.

### 7.2 FireDog — firewall management (proposed, to build)

Server: `firedog-mcp`. Django backend managing firewall rules on remote Linux
targets. Must follow §2–§6. Proposed phase-1 tools (confirm against FireDog's
real domain before building):

| Tool | Returns (proposed) |
|---|---|
| `list_targets` | Managed hosts / firewalls with status |
| `get_target` | One target's detail + connectivity state |
| `list_rules` | Firewall rules, filterable by target / chain / action |
| `get_rule` | One rule's detail |
| `get_policy_summary` | Rollup: rule counts, drift, last-sync, exposed ports |

**Phase-2 candidates:** `apply_rule`, `revert_rule`, `sync_target`.

### 7.3 CyberSheppard — (proposed, to build)

Server: `cybersheppard-mcp`. Domain and data model to be confirmed. Once known,
map its primary entities onto the same `list_* / get_* / *_summary` conventions
and record the concrete catalog here.

---

## 8. Compliance checklist (per product)

Before a product's MCP server is considered contract-compliant:

- [ ] `POST /api/mcp`, JSON-RPC 2.0, single + batch requests.
- [ ] `initialize`, `ping`, `tools/list`, `tools/call`, `notifications/initialized`.
- [ ] `serverInfo.name = <product>-mcp`, version from the product package.
- [ ] Bearer API-key auth reusing the product's auth middleware; SHA-256 hashing.
- [ ] API keys are per-user, revocable, optional-expiry, impersonate the owner.
- [ ] MCP path CSRF-exempt and Bearer-only (no ambient cookie reliance).
- [ ] Tool names follow §4; read tools never mutate.
- [ ] Response envelope and error split follow §5.
- [ ] `list_*` support `limit`/`offset` with the 50/200 defaults.
- [ ] Internal failures logged server-side, generic message to client.
