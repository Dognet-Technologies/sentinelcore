# 08 — Plugin System

## Current state (v1.0.1)

The plugin system provides **registration, configuration, enable/disable, and synchronous execution of plugins managed in memory** (`src/plugins/mod.rs`). It is intentionally minimal in this release.

```rust
pub trait Plugin: Send + Sync {
    fn name(&self) -> &str;
    fn version(&self) -> &str;
    fn execute(&self, action: &str, data: &Value) -> Result<Value>;
}
```

`PluginManager` keeps `(PluginMetadata, Box<dyn Plugin>)` pairs behind an `RwLock` and enforces name/version consistency at registration. Execution refuses disabled plugins. Plugin metadata and per-plugin JSONB config persist in the database; the manager state is rebuilt at startup.

The directory scanner (`plugins.directory`, default `./plugins`) enumerates candidates defensively — paths are canonicalized and checked for containment against the base directory (symlink/path-traversal defense, CWE-22) — but **dynamic loading of native `.so`/`.dll` plugins is not yet wired** (the loader module is a stub).

Plugin support is **disabled by default** in configuration (`plugins.enabled: false`).

## Admin API

| Endpoint | Purpose |
|---|---|
| `GET /api/plugins`, `GET /api/plugins/:id` | List / inspect (any authenticated user) |
| `POST /api/plugins` | Register/install |
| `PUT /api/plugins/:id` | Update configuration |
| `POST /api/plugins/:id/toggle` | Enable / disable |
| `DELETE /api/plugins/:id` | Uninstall |
| `POST /api/plugins/upload` | Upload a plugin package |
| `POST /api/plugins/scan` | Rescan the plugin directory |
| `POST /api/plugins/:id/execute` | Execute an action |

The OpenVAS/GMP connector is a **built-in plugin** with dedicated config/test endpoints — see [07 — Integrations](07-integrations.md#openvas--gmp-connector-built-in-plugin).

## Bundled plugins

Four Python plugins ship in `vulnerability-manager/plugins/`, each with a `plugin.yaml` manifest and a `main.py` entry point:

| Plugin | Type | Capabilities |
|---|---|---|
| `network_discovery` | analysis | Host discovery (`scan`, `ping`), topology generation |
| `vulnerabilities_export` | export | Vulnerability data export |
| `multilingual_pack` | i18n | Additional UI languages |
| `themes_extension` | ui | Extra UI themes |

## Manifest format (`plugin.yaml`)

```yaml
name: network_discovery            # machine name (must match code)
display_name: "Network Discovery"
version: "1.0.0"
author: "Dognet Technologies"
description: "Discovers alive hosts and builds a topology map"
language: python                   # implementation language
type: analysis                     # analysis | export | i18n | ui | ...
entry_point: main.py

capabilities:                      # actions the plugin exposes
  - scan
  - ping
  - topology

config:                            # default config (editable via API/UI)
  default_network: "192.168.1.0/24"
  max_workers: 50
  timeout: 2

permissions:                       # declared permission needs
  - network_scan
  - host_discovery

requirements: []                   # Python dependencies
icon: "🌐"
tags: [network, discovery, topology, mapping]
```

## Roadmap (planned for v1.0.5 — not implemented)

Documented in code comments (`src/plugins/mod.rs`):

- Lua scripting support (mlua/rlua)
- Dynamic loading of native plugins (`.so`/`.dll`)
- Sandboxing and security boundaries for plugin execution
- Hot reload
- Plugin marketplace integration

Treat any external description of these as future work, not current capability.
