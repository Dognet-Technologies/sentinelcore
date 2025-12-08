#!/bin/bash
# SentinelCore VM Provisioning Script
# Installs and configures SentinelCore on Debian 13

set -e

echo "========================================="
echo "SentinelCore VM Provisioning Started"
echo "========================================="

# Update system
echo "📦 Updating system packages..."
apt-get update
apt-get upgrade -y
apt-get dist-upgrade -y

# Install base dependencies
echo "📦 Installing system dependencies..."
apt-get install -y \
    curl \
    wget \
    git \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    postgresql \
    postgresql-contrib \
    nginx \
    ufw \
    fail2ban \
    htop \
    vim \
    tmux \
    net-tools \
    dnsutils \
    ca-certificates \
    gnupg \
    lsb-release

# Install Node.js 20 LTS
echo "📦 Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# Install Rust
echo "📦 Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable
source /root/.cargo/env

# Make Rust available for all users
cp -r /root/.cargo /home/microcyber/
chown -R microcyber:microcyber /home/microcyber/.cargo

# Clone SentinelCore repository
echo "📦 Cloning SentinelCore repository..."
cd /opt
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore

# Use main branch or latest release
git checkout main

# Setup PostgreSQL
echo "🗄️  Setting up PostgreSQL..."
systemctl enable postgresql
systemctl start postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE vulnerability_manager;
CREATE USER vlnman WITH PASSWORD 'changeme_on_first_boot';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
ALTER DATABASE vulnerability_manager OWNER TO vlnman;
\q
EOF

# Configure PostgreSQL for local connections
echo "host    vulnerability_manager    vlnman    127.0.0.1/32    scram-sha-256" >> /etc/postgresql/15/main/pg_hba.conf
systemctl restart postgresql

# Set DATABASE_URL for build
export DATABASE_URL="postgresql://vlnman:changeme_on_first_boot@localhost:5432/vulnerability_manager"

# Run migrations
echo "🗄️  Running database migrations..."
cd /opt/sentinelcore/vulnerability-manager
sudo -u microcyber -H sh -c "source /home/microcyber/.cargo/env && cargo install sqlx-cli --no-default-features --features postgres"
sudo -u microcyber -H sh -c "source /home/microcyber/.cargo/env && DATABASE_URL='$DATABASE_URL' sqlx database create"
sudo -u microcyber -H sh -c "source /home/microcyber/.cargo/env && DATABASE_URL='$DATABASE_URL' sqlx migrate run"

# Regenerate SQLx cache
echo "🔧 Regenerating SQLx query cache..."
cd /opt/sentinelcore
sudo -u microcyber -H sh -c "source /home/microcyber/.cargo/env && DATABASE_URL='$DATABASE_URL' /opt/sentinelcore/scripts/deployment/regenerate-sqlx-cache.sh"

# Build backend
echo "🔨 Building Rust backend..."
cd /opt/sentinelcore/vulnerability-manager
sudo -u microcyber -H sh -c "source /home/microcyber/.cargo/env && SQLX_OFFLINE=true cargo build --release"

# Build frontend
echo "🎨 Building React frontend..."
cd /opt/sentinelcore/vulnerability-manager-frontend
sudo -u microcyber npm install
sudo -u microcyber npm run build

# Install backend binary
echo "📦 Installing SentinelCore..."
mkdir -p /opt/sentinelcore/bin
mkdir -p /opt/sentinelcore/frontend
mkdir -p /var/lib/sentinelcore/uploads
mkdir -p /var/log/sentinelcore

cp /opt/sentinelcore/vulnerability-manager/target/release/vulnerability-manager /opt/sentinelcore/bin/
cp -r /opt/sentinelcore/vulnerability-manager-frontend/build/* /opt/sentinelcore/frontend/
cp /opt/sentinelcore/.env.production.example /opt/sentinelcore/.env

# Generate secure secrets
JWT_SECRET=$(openssl rand -base64 64)
DB_PASSWORD=$(openssl rand -base64 32)

# Update .env file
cat > /opt/sentinelcore/.env << EOF
# SentinelCore Production Configuration
# Generated during VM build on $(date)

# Database
DATABASE_URL=postgresql://vlnman:${DB_PASSWORD}@localhost:5432/vulnerability_manager
VULN_DATABASE_MAX_CONNECTIONS=20
VULN_DATABASE_MIN_CONNECTIONS=5

# JWT Authentication
JWT_SECRET=${JWT_SECRET}

# Server
VULN_SERVER_HOST=0.0.0.0
VULN_SERVER_PORT=8080
VULN_SERVER_ENABLE_TLS=false

# Security
VULN_SECURITY_CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
VULN_SECURITY_RATE_LIMIT_ENABLED=true
VULN_SECURITY_RATE_LIMIT_REQUESTS_PER_MINUTE=100
VULN_SECURITY_RATE_LIMIT_BURST_SIZE=200

# Logging
RUST_LOG=info,sqlx=warn
VULN_LOG_LEVEL=info
VULN_LOG_FILE=/var/log/sentinelcore/app.log
VULN_LOG_FORMAT=json

# Application
APP_ENV=production
NODE_ENV=production

# SQLx (Build time)
SQLX_OFFLINE=true
EOF

# Update PostgreSQL password
sudo -u postgres psql << EOF
ALTER USER vlnman WITH PASSWORD '${DB_PASSWORD}';
\q
EOF

# Set permissions
chown -R microcyber:microcyber /opt/sentinelcore
chown -R microcyber:microcyber /var/lib/sentinelcore
chown -R microcyber:microcyber /var/log/sentinelcore
chmod 600 /opt/sentinelcore/.env

# Create systemd service
echo "⚙️  Creating systemd service..."
cat > /etc/systemd/system/sentinelcore.service << 'EOF'
[Unit]
Description=SentinelCore Vulnerability Management System
After=network.target postgresql.service
Wants=postgresql.service

[Service]
Type=simple
User=microcyber
Group=microcyber
WorkingDirectory=/opt/sentinelcore
EnvironmentFile=/opt/sentinelcore/.env
ExecStart=/opt/sentinelcore/bin/vulnerability-manager
Restart=on-failure
RestartSec=10
StandardOutput=append:/var/log/sentinelcore/app.log
StandardError=append:/var/log/sentinelcore/error.log

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/sentinelcore /var/log/sentinelcore

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable sentinelcore

# Configure Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/sentinelcore << 'EOF'
server {
    listen 80;
    server_name _;

    client_max_body_size 100M;

    # API proxy
    location /api/ {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
    }

    # Frontend static files
    location / {
        root /opt/sentinelcore/frontend;
        try_files $uri $uri/ /index.html;
        add_header Cache-Control "public, max-age=3600";
    }

    # Uploads
    location /uploads/ {
        alias /var/lib/sentinelcore/uploads/;
        add_header Cache-Control "public, max-age=86400";
    }
}
EOF

ln -sf /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable nginx

# Configure firewall
echo "🔒 Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow 22/tcp comment 'SSH'
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'

# Enable fail2ban
systemctl enable fail2ban
systemctl start fail2ban

# Create admin user in database
echo "👤 Creating admin user..."
ADMIN_PASSWORD_HASH=$(echo -n "admin" | /opt/sentinelcore/bin/vulnerability-manager hash-password 2>/dev/null || echo '$argon2id$v=19$m=19456,t=2,p=1$aGFzaGluZ3NhbHQ$placeholder')

sudo -u postgres psql -d vulnerability_manager << EOF
INSERT INTO users (id, email, password_hash, full_name, role, is_active, is_locked, created_at, updated_at)
VALUES (
    gen_random_uuid(),
    'admin@sentinelcore.local',
    '${ADMIN_PASSWORD_HASH}',
    'Administrator',
    'admin',
    true,
    false,
    NOW(),
    NOW()
) ON CONFLICT (email) DO NOTHING;
\q
EOF

# Create welcome message
cat > /etc/motd << 'EOF'
╔══════════════════════════════════════════════════════════╗
║                                                          ║
║              Welcome to SentinelCore VM                  ║
║     Enterprise Vulnerability Management System          ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝

First-time setup required!

Run the configuration wizard:
  sudo sentinelcore-first-boot

Default credentials (CHANGE IMMEDIATELY):
  Email: admin@sentinelcore.local
  Password: admin

Services:
  - SentinelCore: systemctl status sentinelcore
  - PostgreSQL: systemctl status postgresql
  - Nginx: systemctl status nginx

Access SentinelCore:
  - Web UI: http://<vm-ip>
  - API: http://<vm-ip>/api

Documentation:
  /opt/sentinelcore/docs/

Support:
  https://github.com/Dognet-Technologies/sentinelcore

EOF

echo "========================================="
echo "✅ SentinelCore VM Provisioning Complete"
echo "========================================="
