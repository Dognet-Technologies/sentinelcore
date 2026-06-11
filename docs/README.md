# SentinelCore — Technical Documentation

Technical reference for SentinelCore, the vulnerability management platform by Dognet Technologies.

This documentation is generated from and verified against the source code on branch `develop/v1.0.1-doc`. When code and docs disagree, the code wins — please open an issue.

## Contents

| Document | What it covers |
|---|---|
| [01 — Overview](01-overview.md) | What SentinelCore does, what it does not do, core workflow |
| [02 — Architecture](02-architecture.md) | Components, processes, request and data flow |
| [03 — Features](03-features.md) | Functional areas in detail |
| [04 — API Reference](04-api-reference.md) | All HTTP endpoints, grouped by area and required role |
| [05 — Roles & Permissions](05-roles-and-permissions.md) | RBAC model, route protection, granular permissions |
| [06 — Data Model](06-data-model.md) | Database schema by domain, migrations, conventions |
| [07 — Integrations](07-integrations.md) | Scanner importers, OpenVAS/GMP connector, JIRA, NVD, EPSS, notifications, SOAR |
| [08 — Plugin System](08-plugin-system.md) | Plugin manager, bundled plugins, manifest format |
| [09 — Background Workers](09-background-workers.md) | All 12 workers: schedule, purpose, configuration |
| [10 — Technical Specifications](10-technical-specs.md) | Stack, configuration, security controls, logging, requirements |

## Repository layout

```
sentinelcore/
├── vulnerability-manager/           # Rust backend (Axum + SQLx + PostgreSQL)
│   ├── src/                         # ~31k LOC
│   ├── migrations/                  # 76 SQL migrations
│   ├── plugins/                     # Bundled Python plugins
│   └── config/                      # default.yaml / production.yaml
├── vulnerability-manager-frontend/  # React 18 + TypeScript + MUI 5 (~32k LOC)
├── packer/                          # VM image build (deployment)
├── scripts/                         # Operational scripts
└── docs/                            # This documentation
```

## Design assets

The Network Topology design system (colors, typography, device icons, UI kit previews) lives in [`NetworkTopology_restyle/`](NetworkTopology_restyle/). It is a design asset package, not prose documentation, and is maintained separately.
