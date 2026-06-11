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

## Target layout

| Item | Value |
|---|---|
| Service user | `sentinelcore` (system user, no login shell) |
| Install root | `/opt/sentinelsuite/sentinelcore` |
| Source checkout | `/opt/sentinelsuite/sentinelcore/src` |
| Application dir (working dir) | `/opt/sentinelsuite/sentinelcore/app` |
| Frontend static files | `/opt/sentinelsuite/sentinelcore/frontend` |
| Log directory | `/var/log/sentinelsuite/sentinelcore/` (backend default) |
| Backend port | `8080` (HTTP, localhost — TLS terminates at nginx) |
| Database | PostgreSQL 17 (Debian 13 default), db `vulnerability_manager`, user `vlnman` |

> **TLS note:** the backend does **not** implement TLS itself (`main.rs` binds plain HTTP; the `enable_tls` config key only produces a warning). HTTPS must be terminated by nginx.

> **Disk:** a full build needs real headroom. The Rust `target/` (~3 GB), Cargo registry, and the frontend `node_modules` (~500 MB) easily exceed a 10 GB disk built alongside a GNOME image. Provision **at least 15 GB** (20 GB comfortable), or free space first (see the cleanup notes in steps 6 and 9). The validation VM was 10 GB and required removing `target/`/`node_modules` after the builds to stay under quota.

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
    sudo ca-certificates gnupg

# Node.js 20 LTS (for the frontend build)
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo bash -
sudo apt-get install -y nodejs
```

Rust (latest stable, via rustup — do this as your build user, not root):

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source "$HOME/.cargo/env"
```

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

```bash
cd /opt/sentinelsuite/sentinelcore/src
sudo -u sentinelcore git clone https://github.com/Dognet-Technologies/sentinelcore.git .
# Pick the branch/tag you are deploying:
sudo -u sentinelcore git checkout main
```

The repository contains both the backend (`vulnerability-manager/`) and the frontend (`vulnerability-manager-frontend/`).

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

The admin bootstrap happens **after** the service is running (step 11), because the only reliable way to get a correct Argon2 hash is to let the backend hash the password for you.

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

If the build fails with "query metadata not found / mismatched" errors, the committed cache is stale for your branch — regenerate it against the live, fully migrated database and retry:

```bash
cargo install sqlx-cli --no-default-features --features postgres
DATABASE_URL="$DATABASE_URL" cargo sqlx prepare
SQLX_OFFLINE=true cargo build --release
```

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

## 9. Build and deploy the frontend

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

## 10. nginx

`/etc/nginx/sites-available/sentinelcore`:

```nginx
server {
    listen 80;
    server_name sentinelcore.example.com;

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

## 11. systemd service

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

## 12. Verification

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

## 13. Optional hardening

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
| Login OK but session drops immediately on plain HTTP | `cookies.secure: true` over HTTP — browser refuses the cookie (step 10) |
| 401/403 on every POST from the UI | CSRF token cookie not reaching the browser — check nginx proxies `/api/` with cookies intact and the site origin matches `security.cors.allowed_origins` |
| `admin` account exists but login says "Invalid credentials" | A manual `INSERT` with the seed hash was used — that hash is not `admin123`. Delete the row and use register-then-promote (step 5) |
| `npm ci` aborts with `ECONNRESET` / `network aborted` | Transient registry reset — re-run with `--fetch-retries=5` (step 9) |
| Discovery reports devices but topology/DB stays empty | The target was a hyphen range; arp-scan silently scanned one host. Use CIDR (step 12 warning) |
| Discovery "devices_found" looks 1–2 higher than real hosts | Cosmetic: arp-scan footer lines are counted before the IP parse drops them. Real hosts persist correctly; harmless |
