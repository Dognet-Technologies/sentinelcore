# SentinelCore — Installation Guide (Debian 13)

Step-by-step installation of SentinelCore on a fresh **Debian 13 (trixie)** VM: dependencies, PostgreSQL, migrations, backend build, frontend build, nginx, systemd, and the privilege setup required by network discovery.

This guide was **validated by a full clean install on a Debian 13 VM** (PostgreSQL 17.10, Rust 1.96, Node 20). Every command here was executed end-to-end; the notes call out the few places where the obvious approach does not work. Where older scripts in `scripts/` or `packer/` disagree with this document, **this document wins** (several of those scripts are stale).

## Filesystem convention — `/opt/sentinelsuite/`

SentinelCore is one component of the **Sentinel Suite** (alongside FireDog and CyberSheppard). By convention all suite software installs under `/opt/sentinelsuite/<component>/`, so multiple components can coexist on the same host:

```
/opt/sentinelsuite/
├── sentinelcore/     # this product
├── firedog/          # (if installed)
└── cybersheppard/    # (if installed)
```

Logs follow the same convention under `/var/log/sentinelsuite/<component>/`.

## Two-user model

SentinelCore (and the rest of the Sentinel Suite) is installed under **two distinct Linux accounts** and the rest of this document keeps them carefully separate. Mixing them up is the single most common cause of "step works as root, breaks as the daemon" failures:

| Account | Role | Shell / login | Sudo |
|---|---|---|---|
| `microcyber` | **Operator** — SSH login, builds, manages services across the whole suite | normal interactive shell | full `sudo` (password-prompted) |
| `sentinelcore` | **Service** — owns the runtime tree, runs the systemd unit | `/usr/sbin/nologin`, no home outside `/opt/...` | only `NOPASSWD: /usr/bin/nmap, /usr/sbin/arp-scan` (step 8) |

Unless a step explicitly says otherwise, **every command in this guide is run as the operator user (`microcyber` by convention — see Prerequisites)**, with `sudo` for the privileged ones. The few places that need the service user are called out with `sudo -u sentinelcore …` or `install -o sentinelcore …` inline.

## Target layout

| Item | Value |
|---|---|
| Operator user | `microcyber` (SSH login, sudo, builds — see Prerequisites) |
| Service user | `sentinelcore` (system user, no login shell — see section 2) |
| Install root | `/opt/sentinelsuite/sentinelcore` |
| Source checkout | `/opt/sentinelsuite/sentinelcore/src` |
| Application dir (working dir) | `/opt/sentinelsuite/sentinelcore/app` |
| Frontend static files | `/opt/sentinelsuite/sentinelcore/frontend` |
| Log directory | `/var/log/sentinelsuite/sentinelcore/` (backend default) |
| Backend port | `8080` (HTTP, localhost — TLS terminates at nginx) |
| Database | PostgreSQL 17 (Debian 13 default), db `vulnerability_manager`, user `vlnman` |

> **TLS note:** the backend does **not** implement TLS itself (`main.rs` binds plain HTTP; the `enable_tls` config key only produces a warning). HTTPS must be terminated by nginx.

> **Disk:** a full build needs real headroom. The Rust `target/` (~1.5 GB after a clean release build, ~3 GB with incremental + debug artifacts), Cargo registry (~400 MB), `node_modules` (~700 MB), and the binary copy in `app/` (~26 MB) easily exceed a 10 GB disk built alongside a GNOME image. **At least 20 GB is recommended**; a 10 GB VM hits 98% usage during the second `cargo build` and a single re-build wedges it (verified — `error: No space left on device`). On a tight disk you must `rm -rf target/ node_modules/` between full builds. For an iterative dev/test box plan **20+ GB**.

---

## Prerequisites

You need a normal (non-root) Linux account with **interactive sudo** to run this guide. Across the Sentinel Suite we standardize on **`microcyber`** as the operator name — preconfigured Suite VMs ship with it and the **default password `Admin2026!!`** (change it at first login via `passwd`, the install does not require it after that). On a hand-built host, any sudo-capable user works; if you keep the naming convention the rest of the suite documentation will line up. Do **not** give the operator a blanket `NOPASSWD: ALL` — the only `NOPASSWD` rule in this guide is the minimal one in step 8, scoped to the `sentinelcore` *service* user and to `nmap` + `arp-scan` only.

All subsequent commands are run as that operator user, with `sudo` for the privileged ones.

---

## 1. System packages

```bash
sudo apt-get update && sudo apt-get upgrade -y

# Build toolchain + runtime dependencies
sudo apt-get install -y \
    curl wget git build-essential pkg-config libssl-dev \
    postgresql postgresql-contrib \
    nginx \
    nmap arp-scan \
    rsync \
    sudo ca-certificates gnupg

# Node.js 20 LTS (for the frontend build)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

Rust (latest stable, via rustup — do this as your build user, not root):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
rustc --version   # should print 1.94+ — the SQLx 0.9 toolchain floor
```

> **If rustup was already installed for another project**, the active default may still point at an older toolchain (e.g. 1.88). Force-update and re-pin stable as the default before continuing — otherwise the `cargo sqlx prepare` fallback in step 6 errors out with *"requires rustc 1.94.0 or newer"*:
> ```bash
> rustup update stable
> rustup default stable
> ```

## 2. Service user and directories

```bash
sudo useradd --system --home /opt/sentinelsuite/sentinelcore --shell /usr/sbin/nologin sentinelcore

sudo mkdir -p /opt/sentinelsuite/sentinelcore/{src,app,frontend}
sudo mkdir -p /opt/sentinelsuite/sentinelcore/app/{config,uploads,reports,plugins}
sudo mkdir -p /var/log/sentinelsuite/sentinelcore
sudo chown -R sentinelcore:sentinelcore /opt/sentinelsuite/sentinelcore /var/log/sentinelsuite/sentinelcore
```

The application resolves `config/`, `uploads/`, `reports/` and `plugins/` **relative to its working directory** — that is why `/opt/sentinelsuite/sentinelcore/app` exists and the systemd unit sets `WorkingDirectory` to it. The log directory must exist and be writable by the service user, otherwise the backend falls back to journal-only logging (it logs a warning, it does not fail).

## 3. Clone the repository

Clone as **`microcyber`** — the operator account from step 0, which owns the Cargo install and will run the build. Step 2 created `src/` owned by `sentinelcore`, so first hand it over; Cargo needs write access to `src/vulnerability-manager/target/` and `sentinelcore` has no shell and no Cargo install, which would make every subsequent build command painful.

```bash
sudo chown -R microcyber:microcyber /opt/sentinelsuite/sentinelcore/src
cd /opt/sentinelsuite/sentinelcore/src
git clone https://github.com/Dognet-Technologies/sentinelcore.git .
# Pick the branch/tag you are deploying:
git checkout main
```

The repository contains both the backend (`vulnerability-manager/`) and the frontend (`vulnerability-manager-frontend/`). Source ownership stays with `microcyber` for the lifetime of the install — only the built artifacts under `app/` and `frontend/` are handed over to `sentinelcore`/`www-data` respectively (steps 6 and 10).

## 4. PostgreSQL

Debian 13 ships PostgreSQL 17. Default `pg_hba.conf` already allows `scram-sha-256` on `127.0.0.1`, so no edit is normally needed.

```bash
sudo systemctl enable --now postgresql

# Generate a strong password and keep it for the config step
DB_PASS="$(openssl rand -base64 24 | tr -d '/+=' )"
echo "DB password: ${DB_PASS}"   # save it now

sudo -u postgres psql <<EOF
CREATE USER vlnman WITH PASSWORD '${DB_PASS}';
CREATE DATABASE vulnerability_manager OWNER vlnman;
EOF
```

## 5. Database migrations

> **Important:** the automatic migration runner is intentionally disabled in `main.rs`, and `sqlx migrate run` must **not** be used blindly (the sqlx tracking state is not authoritative in this repo). Apply the SQL files directly with `psql`, in lexical order.
>
> **Skip the seed files** `099_realistic_workflow_seed.sql` and `999_seed_data.sql` in production: they load demo data, and `999` is not even compatible with the fully migrated schema (it inserts `team_members` rows without the `user_id` that migration 021 made NOT NULL).

```bash
export DATABASE_URL="postgresql://vlnman:${DB_PASS}@localhost:5432/vulnerability_manager"

cd /opt/sentinelsuite/sentinelcore/src/vulnerability-manager
for f in migrations/*.sql; do
    case "$(basename "$f")" in
        099_*|999_*) echo "SKIP seed: $f"; continue ;;
    esac
    echo ">> $f"
    psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"
done
```

### Create the first admin user

The admin bootstrap happens **after** the service is running (step 12), because the only reliable way to get a correct Argon2 hash is to let the backend hash the password for you.

> **Do not** copy the password hash from `999_seed_data.sql` into a manual `INSERT`. That seed hash uses throwaway Argon2 parameters (`m=16`) and does **not** correspond to `admin123` — a manual insert with it produces an account that cannot log in (verified during the validation install). Use the register-then-promote flow below instead.

The procedure (run it once the backend and nginx are up):

```bash
# 1. Obtain a CSRF token (issued as a cookie on any GET)
curl -s -c /tmp/sc.jar http://localhost/api/health >/dev/null
CSRF=$(awk '/XSRF-TOKEN/{print $7}' /tmp/sc.jar)

# 2. Register the admin account (created with role 'user')
curl -s -b /tmp/sc.jar -H "X-CSRF-Token: $CSRF" -H 'Content-Type: application/json' \
  -d '{"username":"admin","email":"admin@example.com","password":"<STRONG_PASSWORD>","skip_email_verification":true}' \
  http://localhost/api/auth/register

# 3. Promote it to admin (only DB step; the password is already correctly hashed)
psql "$DATABASE_URL" -c "UPDATE users SET role='admin' WHERE username='admin';"
```

`skip_email_verification: true` lets the account log in immediately. (Login also works with an unverified email — verification only changes the welcome message — but skipping is cleaner for a service account.) Pick a password that satisfies the production policy: **≥ 12 chars, upper + lower + number + special**.

## 6. Build the backend

The repo commits the SQLx offline query cache (`.sqlx/`), so the standard build is offline:

```bash
cd /opt/sentinelsuite/sentinelcore/src/vulnerability-manager
SQLX_OFFLINE=true cargo build --release
```

If the build fails with `SQLX_OFFLINE=true but there is no cached data for this query` (or similar metadata mismatches), the committed cache is stale for your branch — regenerate it against the live, fully migrated database and retry:

```bash
cargo install sqlx-cli --no-default-features --features postgres
DATABASE_URL="$DATABASE_URL" cargo sqlx prepare
SQLX_OFFLINE=true cargo build --release
```

> Verified on `develop/v1.0.1` at the time of the v1.0.1 beta cut: the committed `.sqlx/` lagged a few migrations, so a fresh install **does** require the `cargo sqlx prepare` step. Plan on it taking an extra ~1 min of build time on top of the release build. Treat the missing-query error as a known recovery path, not a red flag.

Install the artifacts:

```bash
sudo install -o sentinelcore -g sentinelcore -m 755 \
    target/release/vulnerability-manager /opt/sentinelsuite/sentinelcore/app/vulnerability-manager

# Bundled plugins (optional — only used if plugins.enabled: true)
sudo cp -r plugins/* /opt/sentinelsuite/sentinelcore/app/plugins/
sudo chown -R sentinelcore:sentinelcore /opt/sentinelsuite/sentinelcore/app/plugins

# Reclaim ~3 GB once the binary is installed (optional, for tight disks —
# target/ is only needed for the next rebuild)
# rm -rf target
```

The release build took ~3 minutes on the validation VM (10 vCPU). With the committed `.sqlx/` cache the offline build worked on the first try — no `cargo sqlx prepare` was needed.

## 7. Backend configuration

Configuration layering (verified in `src/config/mod.rs`): a `default.yaml` **embedded in the binary at compile time** → `config/<APP_ENV>.yaml` from the working directory → environment variables with prefix `VULN_`.

Two pitfalls to be aware of:

1. **No variable interpolation in YAML.** The sample `config/production.yaml` in the repo contains `"${DATABASE_URL}"` / `"${JWT_SECRET}"` placeholders — the config loader does **not** expand them; left as-is the boot fails secret validation. Write real values into the file and protect it with permissions.
2. **`VULN_*` env overrides do not work for nested snake_case keys.** The loader splits env names on every `_`, so `VULN_DATABASE_URL` → `database.url` works, but e.g. `VULN_AUTH_SECRET_KEY` → `auth.secret.key` does **not** reach `auth.secret_key`. Treat the YAML file as the single source of truth.

Create `/opt/sentinelsuite/sentinelcore/app/config/production.yaml`:

```yaml
server:
  host: "127.0.0.1"        # only nginx talks to the backend
  port: 8080
  enable_tls: false        # TLS terminates at nginx

database:
  url: "postgresql://vlnman:<DB_PASS>@localhost:5432/vulnerability_manager"
  max_connections: 30
  connection_timeout_seconds: 10
  idle_timeout_seconds: 600
  max_lifetime_seconds: 1800

auth:
  secret_key: "<output of: openssl rand -base64 64>"   # min 32 chars, enforced at boot
  token_duration_hours: 8
  password_policy:
    min_length: 12
    max_length: 128
    require_uppercase: true
    require_lowercase: true
    require_numbers: true
    require_special_chars: true
    special_chars: "!@#$%^&*()_+-=[]{}|;:,.<>?"
    prevent_common_passwords: true

security:
  cors:
    enabled: true
    allowed_origins:
      - "https://sentinelcore.example.com"   # your site origin (scheme + host)
  csrf:
    enabled: true
    secure_cookie: true      # set false only if serving plain HTTP
  cookies:
    secure: true             # set false only if serving plain HTTP
    same_site: "Strict"

# ────────────────────────────────────────────────────────────────────
# IMPORTANT — `security.cors.allowed_origins`
#
# Must list the EXACT site origin the browser uses (scheme + host
# + optional non-default port). Every request whose `Origin` header
# does not match the list is blocked by the backend with a CORS error,
# and the UI shows "Network error / Failed to fetch" on every action.
#
# Common pitfalls:
#   - DHCP-assigned IP changes after a reboot → the origin no longer
#     matches what's in this list. Either pin the IP (static or DHCP
#     reservation), or update this list after each change and reload
#     the service:
#         sudo systemctl restart sentinelcore
#   - HTTP vs HTTPS mismatch: if nginx serves HTTP only (lab/internal),
#     the origin is `http://…`, not `https://`. Adjust accordingly.
#   - Port: include the port only if it's non-default (e.g. `:8443`).
# ────────────────────────────────────────────────────────────────────

plugins:
  directory: "./plugins"
  enabled: false             # opt-in

network:
  interface: "ens18"         # your scan interface — check with: ip -br link
  default_scan_timeout: 500
  max_scan_workers: 50

log:
  level: "info"
  file: null                 # file logging is driven by env vars, see systemd unit
```

```bash
sudo chown sentinelcore:sentinelcore /opt/sentinelsuite/sentinelcore/app/config/production.yaml
sudo chmod 600 /opt/sentinelsuite/sentinelcore/app/config/production.yaml
```

Boot-time validation (with `APP_ENV=production`): the JWT secret must be ≥ 32 chars and not the dev default, and the database password must not be the dev default — otherwise the service refuses to start.

## 8. Network discovery privileges (nmap / arp-scan)

> **Different user from step 0.** The sudoers drop-in below is for the `sentinelcore` *service* user (created in step 2), not for the `microcyber` operator user. The two are intentionally separate: `microcyber` uses regular password-prompted `sudo` only during install, while the daemon needs a tiny, NOPASSWD-scoped rule for exactly two binaries so that automated scans don't hang waiting for a TTY.

Discovery shells out to `nmap` and `arp-scan`. When the service does not run as root, every invocation is prefixed with **`sudo -n`** (non-interactive). Two supported setups — pick **one**:

### Option A — sudoers (recommended, matches the code's default path)

```bash
sudo tee /etc/sudoers.d/sentinelcore-discovery >/dev/null <<'EOF'
# SentinelCore network discovery: allow the service user to run the two
# scan binaries as root without password. Keep this list minimal.
sentinelcore ALL=(root) NOPASSWD: /usr/bin/nmap, /usr/sbin/arp-scan
EOF
sudo chmod 440 /etc/sudoers.d/sentinelcore-discovery
sudo visudo -c   # syntax check
```

With this option the systemd unit **must not** set `NoNewPrivileges=true` (it would silently break `sudo`).

### Option B — file capabilities + `SENTINELCORE_NO_SUDO=1`

Setting `SENTINELCORE_NO_SUDO=1` in the unit makes the backend execute the tools directly; grant them raw-socket capabilities:

```bash
sudo setcap cap_net_raw,cap_net_admin,cap_net_bind_service+ep /usr/bin/nmap
sudo setcap cap_net_raw+ep /usr/sbin/arp-scan
```

Trade-offs: capabilities apply to **every user** on the host (broader exposure than the per-user sudoers rule), and some nmap features (`-O`, `-sU`, full TCP SYN) behave better under real root via sudo. On the upside, the unit can then enable `NoNewPrivileges=true`.

In both cases the backend verifies the tools at startup and logs a warning (without aborting) if discovery cannot work; failed privileged scans fall back to unprivileged ping scans where possible.

## 9. External scanner integrations (optional)

The built-in plugin `openvas_integration` lets SentinelCore talk to a Greenbone Vulnerability Management (GVM/OpenVAS) instance via the **Greenbone Management Protocol (GMP)**. The plugin is **opt-in**: it stays disabled until you activate it in `/plugins`, so this step is only required if you actually want to import scans from OpenVAS.

The Rust backend does not embed a GMP client — instead, it shells out to `gvm-cli` (part of the `gvm-tools` package) over TLS or UNIX socket. So the host needs `gvm-tools` installed and visible in `PATH` for the `sentinelcore` service user.

### Why pipx and not apt

Debian 13 does **not** ship `python3-gvm` / `gvm-tools` packages — `apt-cache search gvm-tools` returns nothing. The recommended way to install the upstream Python tooling is **pipx with `--global`**, which puts the executables in `/usr/local/bin/` (already in `PATH` for systemd units, including services running as `sentinelcore`).

```bash
# 1. Install pipx (Debian 13 ships pipx 1.7+, which supports --global).
sudo apt-get install -y pipx

# 2. Install gvm-tools system-wide. Symlinks land in /usr/local/bin/.
sudo pipx install --global gvm-tools

# 3. Verify: should print the usage line.
gvm-cli --help | head -3
ls -l /usr/local/bin/gvm-cli /usr/local/bin/gvm-script /usr/local/bin/gvm-pyshell
```

Expected installed version: `gvm-tools 26.x` (the older 25.x `[Auth]` config-file section is deprecated and ignored — the plugin already passes credentials via `--gmp-username/--gmp-password` flags, so no extra wiring is needed).

### Reaching a remote GVM (optional)

If your Greenbone instance runs on a separate host (typical: Greenbone Community Edition is a Docker stack on a separate scanner VM), GMP is only reachable via the gvmd UNIX socket inside that stack by default. Two options:

- **Bind the socket via socat + TLS on the scanner host.** Then point the plugin at `tcp://<scanner-host>:9390` over TLS. The plugin's "Configura" dialog at `/plugins` accepts host/port + GMP credentials.
- **Run SentinelCore and gvmd on the same host** and configure the plugin with `socket_path = /var/run/gvmd/gvmd.sock` (or wherever your distribution mounts it).

### Smoke test from the SentinelCore host

```bash
gvm-cli --gmp-username admin --gmp-password '<gmp-pass>' \
    tls --hostname <scanner-host> --port 9390 \
    --xml '<get_version/>'
# Expected: <get_version_response status="200" ...><version>22.x</version></get_version_response>
```

If you do not run any external scanner integration, you can safely skip this section — the rest of the installation does not depend on `gvm-tools`.

## 10. Build and deploy the frontend

```bash
cd /opt/sentinelsuite/sentinelcore/src/vulnerability-manager-frontend
# --fetch-retries hardens against transient registry resets (npm ci hit an
# ECONNRESET mid-download on the validation VM and aborted; retrying succeeded).
npm ci --no-audit --no-fund --fetch-retries=5 --fetch-retry-maxtimeout=120000
npm run build

sudo cp -r build/* /opt/sentinelsuite/sentinelcore/frontend/
sudo chown -R www-data:www-data /opt/sentinelsuite/sentinelcore/frontend

# Reclaim ~500 MB once the build artifacts are copied out (optional but
# recommended on a tight disk — node_modules is only needed to rebuild)
rm -rf node_modules
```

The SPA calls the API with relative `/api/...` URLs, so no build-time API endpoint is needed — nginx routing does the job. The build is CRA/react-scripts and is memory-hungry; on a small VM (≤ 2 GB RAM) add swap before running it.

## 11. nginx

`/etc/nginx/sites-available/sentinelcore`:

For an IP-only deployment with no DNS, replace the `server_name` value below with `_` (catch-all) — nginx then serves the SPA on every Host header pointing at the box, which is what a lab or air-gapped install actually wants.

```nginx
server {
    listen 80 default_server;
    server_name sentinelcore.example.com;   # or `_` for an IP-only install

    # Scan uploads can be large
    client_max_body_size 100M;

    # API → backend
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_read_timeout 300s;          # long-running imports/scans
    }

    # Uploaded files (avatars) are served by the backend itself
    location /uploads/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
    }

    # SPA static files
    location / {
        root /opt/sentinelsuite/sentinelcore/frontend;
        try_files $uri /index.html;
        add_header Cache-Control "public, max-age=3600";
    }
}
```

```bash
sudo ln -sf /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default
sudo nginx -t && sudo systemctl reload nginx
```

For HTTPS, add certificates with certbot (`sudo apt-get install certbot python3-certbot-nginx && sudo certbot --nginx -d sentinelcore.example.com`). If you stay on plain HTTP (lab/test only), set `security.cookies.secure: false` and `security.csrf.secure_cookie: false` in `production.yaml`, otherwise the browser will drop the auth cookies.

## 12. systemd service

`/etc/systemd/system/sentinelcore.service`:

```ini
[Unit]
Description=SentinelCore Vulnerability Management
After=network-online.target postgresql.service
Wants=network-online.target postgresql.service

[Service]
Type=simple
User=sentinelcore
Group=sentinelcore
WorkingDirectory=/opt/sentinelsuite/sentinelcore/app
ExecStart=/opt/sentinelsuite/sentinelcore/app/vulnerability-manager

Environment=APP_ENV=production
Environment=LOGGING_LEVEL=info
Environment=LOGGING_DESTINATION=/var/log/sentinelsuite/sentinelcore/app.log
# Uncomment only with Option B (capabilities) from step 8:
#Environment=SENTINELCORE_NO_SUDO=1

Restart=on-failure
RestartSec=10

# Hardening — compatible with `sudo -n nmap/arp-scan` (Option A).
# Do NOT add NoNewPrivileges=true with Option A: it breaks sudo.
PrivateTmp=true
ProtectSystem=full
ProtectHome=true
ReadWritePaths=/opt/sentinelsuite/sentinelcore/app /var/log/sentinelsuite/sentinelcore

[Install]
WantedBy=multi-user.target
```

Notes verified against the code:

- `WorkingDirectory` is functional, not cosmetic: `config/production.yaml`, `uploads/`, `reports/` and `plugins/` are all resolved relative to it.
- File logging is configured by the **`LOGGING_LEVEL` / `LOGGING_DESTINATION` environment variables** (or `RUST_LOG`), not by the YAML `log:` section. Level/destination changes require a service restart; log retention (rotation/gzip) is handled live by the built-in retention worker.
- The log directory must pre-exist and belong to the service user (step 2), or the service runs journal-only.

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now sentinelcore
```

## 13. Verification

```bash
# Service up?
systemctl status sentinelcore
journalctl -u sentinelcore -n 50

# Backend health (direct)
curl -s http://127.0.0.1:8080/api/health | python3 -m json.tool

# Through nginx
curl -s http://sentinelcore.example.com/api/health

# Expected startup log lines:
#   ✅ Connected to database
#   ✅ Network scanning system verified and ready   (or a ⚠️ explaining what's missing)
#   ✅ <12 worker start messages>
#   🌐 Server listening on 0.0.0.0:8080
```

Now create the admin account using the **register-then-promote** procedure in step 5 (it requires the running service). Then verify the end-to-end auth + discovery flow:

```bash
# CSRF token
curl -s -c /tmp/sc.jar http://localhost/api/health >/dev/null
CSRF=$(awk '/XSRF-TOKEN/{print $7}' /tmp/sc.jar)

# Login (re-uses the cookie jar; stores the session cookie)
curl -s -b /tmp/sc.jar -c /tmp/sc.jar -H "X-CSRF-Token: $CSRF" -H 'Content-Type: application/json' \
  -d '{"username":"admin","password":"<STRONG_PASSWORD>"}' http://localhost/api/auth/login

# Authenticated call should return the admin profile with "role":"admin"
CSRF=$(awk '/XSRF-TOKEN/{print $7}' /tmp/sc.jar)
curl -s -b /tmp/sc.jar -H "X-CSRF-Token: $CSRF" http://localhost/api/users/me

# Live discovery — note: arp-scan needs a CIDR target (see warning below)
curl -s -b /tmp/sc.jar -H "X-CSRF-Token: $CSRF" -H 'Content-Type: application/json' \
  -d '{"scan_name":"smoke","scan_type":"discovery","target_range":"192.168.1.0/24","include_port_scan":false,"include_os_detection":false}' \
  http://localhost/api/network/scan
```

This exact sequence was run on the validation VM: login returned `role:admin`, and the discovery scan persisted real devices visible at `GET /api/network/topology`.

> **Discovery target format:** use **CIDR** (`192.168.1.0/24`) for the target range. The underlying `arp-scan` does **not** understand nmap-style hyphen ranges (`192.168.1.1-20`) — it treats them as a single host and finds nothing. nmap-style ranges only work for the nmap-based scan paths.

Then open the site in a browser, log in as `admin`, and:

1. set the discovery interface/targets (Settings → Network Discovery);
2. create your real users and teams;
3. if you must keep the temporary install-time sudoers/NOPASSWD broadening, remove it now.

## 14. Optional hardening

```bash
# Firewall: only SSH + HTTP(S) exposed; port 8080 stays loopback-only by config
sudo apt-get install -y ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 22/tcp
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
```

## Troubleshooting

| Symptom | Cause / fix |
|---|---|
| Boot aborts with `SECURITY ERROR: JWT secret_key…` | `auth.secret_key` missing, < 32 chars, or left as a `${…}` placeholder in `production.yaml` |
| `cannot create log directory … falling back to journal-only` | Create `/var/log/sentinelsuite/sentinelcore` owned by `sentinelcore` (step 2) |
| Discovery finds nothing, log shows `sudo: a password is required` | Sudoers file missing/wrong (step 8A), or `NoNewPrivileges=true` left in the unit |
| Discovery works as root test but not as service | Using Option B without `SENTINELCORE_NO_SUDO=1`, or capabilities not set on the right binary paths |
| Backend build: SQLx "query metadata" errors | Stale `.sqlx/` cache → `cargo sqlx prepare` against the migrated DB (step 6) |
| `cargo install sqlx-cli` fails with `requires rustc 1.94.0 or newer` | The active rustup default toolchain is older than `stable` — usually a pre-existing rustup install left the default pinned to an earlier version. Run `rustup default stable` (step 1 note) and retry |
| Login OK but session drops immediately on plain HTTP | `cookies.secure: true` over HTTP — browser refuses the cookie (step 11) |
| 401/403 on every POST from the UI | CSRF token cookie not reaching the browser — check nginx proxies `/api/` with cookies intact and the site origin matches `security.cors.allowed_origins` |
| `admin` account exists but login says "Invalid credentials" | A manual `INSERT` with the seed hash was used — that hash is not `admin123`. Delete the row and use register-then-promote (step 5) |
| `npm ci` aborts with `ECONNRESET` / `network aborted` | Transient registry reset — re-run with `--fetch-retries=5` (step 10) |
| Discovery reports devices but topology/DB stays empty | The target was a hyphen range; arp-scan silently scanned one host. Use CIDR (step 12 warning) |
| Discovery "devices_found" looks 1–2 higher than real hosts | Cosmetic: arp-scan footer lines are counted before the IP parse drops them. Real hosts persist correctly; harmless |
| OpenVAS plugin: "Connessione OK · GMP X.x" never returns / "gvm-cli not found" | `gvm-tools` not installed or not in the systemd `PATH`. Install with `sudo pipx install --global gvm-tools` (step 9), then restart `sentinelcore`. The default systemd `PATH` already includes `/usr/local/bin` so no drop-in unit is needed when installed `--global` |
| OpenVAS plugin: `gvm-cli exit 1: …deprecated 'Auth' section… EOF` | You have `gvm-tools 25.x` whose `[Auth]` config-file section is silently ignored. `pipx install --global gvm-tools` pulls `26.x`, which the plugin uses correctly (credentials via `--gmp-username/--gmp-password` flags) |
