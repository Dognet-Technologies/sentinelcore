#!/bin/bash
# Setup completo di SentinelCore su Debian 13 (Trixie) headless
# Questo script installa tutto il necessario da zero

set -e

echo "🚀 SentinelCore VM Setup for Debian 13"
echo "========================================"

# Verifica che siamo su Debian
if ! grep -q "Debian" /etc/os-release; then
    echo "❌ This script is for Debian only"
    exit 1
fi

# Aggiorna sistema
echo "📦 Updating system..."
apt-get update
apt-get upgrade -y

# 1. Installa dipendenze di sistema
echo "📚 Installing system dependencies..."
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
    fail2ban

# 2. Installa Node.js 20 LTS
echo "📦 Installing Node.js 20 LTS..."
curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
apt-get install -y nodejs

# 3. Installa Rust (latest stable)
echo "🦀 Installing Rust..."
if ! command -v cargo &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
fi

# 4. Clona repository SentinelCore
echo "📥 Cloning SentinelCore repository..."
cd /opt
if [ -d "sentinelcore" ]; then
    echo "Directory exists, pulling latest changes..."
    cd sentinelcore
    git pull
else
    git clone https://github.com/Dognet-Technologies/sentinelcore.git
    cd sentinelcore
fi

# 5. Checkout alla branch corretta con le P1-P5
git fetch origin
git checkout claude/sentinelcore-production-review-012z1oZTPpQQ9yXf1tJMBVmM

# 6. Compila backend
echo "🔨 Compiling Rust backend..."
cd vulnerability-manager
cargo build --release
cd ..

# 7. Compila frontend
echo "🎨 Building React frontend..."
cd vulnerability-manager-frontend
npm install
npm run build
cd ..

# 8. Configura PostgreSQL
echo "🐘 Configuring PostgreSQL..."
sudo -u postgres psql << EOF
-- Crea database se non esiste
SELECT 'CREATE DATABASE vulnerability_manager'
WHERE NOT EXISTS (SELECT FROM pg_database WHERE datname = 'vulnerability_manager')\gexec

-- Crea utente se non esiste
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_user WHERE usename = 'vlnman') THEN
    CREATE USER vlnman WITH PASSWORD 'changeme_in_production';
  END IF;
END
\$\$;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
EOF

# 9. Esegui migrations
echo "🔄 Running database migrations..."
for migration in /opt/sentinelcore/vulnerability-manager/migrations/*.sql; do
    echo "Running $(basename $migration)..."
    sudo -u postgres psql -d vulnerability_manager -f "$migration"
done

# 10. Crea utente di sistema
echo "👤 Creating system user..."
if ! id -u sentinelcore > /dev/null 2>&1; then
    useradd -r -s /bin/false -d /opt/sentinelcore sentinelcore
fi

# 11. Crea directories e imposta permessi
echo "📁 Setting up directories..."
mkdir -p /var/lib/sentinelcore/uploads
mkdir -p /var/log/sentinelcore
chown -R sentinelcore:sentinelcore /opt/sentinelcore
chown -R sentinelcore:sentinelcore /var/lib/sentinelcore
chown -R sentinelcore:sentinelcore /var/log/sentinelcore

# 12. Crea file .env
echo "⚙️  Creating configuration file..."
if [ ! -f /opt/sentinelcore/.env ]; then
    cat > /opt/sentinelcore/.env << 'ENVFILE'
# Database
DATABASE_URL=postgresql://vlnman:changeme_in_production@localhost:5432/vulnerability_manager
VULN_DATABASE_MAX_CONNECTIONS=20

# JWT Secret (CHANGE THIS!)
VULN_AUTH_SECRET_KEY=CHANGE_THIS_TO_A_RANDOM_256_BIT_HEX_STRING

# Server
VULN_SERVER_HOST=0.0.0.0
VULN_SERVER_PORT=8080
VULN_SERVER_ENABLE_TLS=false

# CORS
VULN_SECURITY_CORS_ALLOWED_ORIGINS=http://localhost

# Rate Limiting
VULN_SECURITY_RATE_LIMIT_ENABLED=true
VULN_SECURITY_RATE_LIMIT_REQUESTS_PER_MINUTE=60
VULN_SECURITY_RATE_LIMIT_BURST_SIZE=100

# Logging
RUST_LOG=info
VULN_LOG_LEVEL=info
VULN_LOG_FORMAT=json

# Application
APP_ENV=production
ENVFILE

    chown sentinelcore:sentinelcore /opt/sentinelcore/.env
    chmod 600 /opt/sentinelcore/.env
fi

# 13. Crea servizio systemd
echo "🔧 Creating systemd service..."
cat > /etc/systemd/system/sentinelcore.service << 'SERVICE'
[Unit]
Description=SentinelCore Vulnerability Manager
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=sentinelcore
Group=sentinelcore
WorkingDirectory=/opt/sentinelcore
EnvironmentFile=/opt/sentinelcore/.env
ExecStart=/opt/sentinelcore/vulnerability-manager/target/release/vulnerability-manager
Restart=always
RestartSec=10

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/sentinelcore /var/log/sentinelcore

# Limits
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
SERVICE

# 14. Configura Nginx
echo "🌐 Configuring Nginx..."
cat > /etc/nginx/sites-available/sentinelcore << 'NGINXCONF'
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;

    # Frontend
    location / {
        root /opt/sentinelcore/vulnerability-manager-frontend/build;
        try_files $uri $uri/ /index.html;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Backend API
    location /api {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Uploads
    location /uploads {
        alias /var/lib/sentinelcore/uploads;
        internal;
    }
}
NGINXCONF

# Rimuovi default se esiste
rm -f /etc/nginx/sites-enabled/default
ln -sf /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/

# Testa configurazione nginx
nginx -t

# 15. Configura firewall (UFW)
echo "🔥 Configuring firewall..."
ufw --force enable
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow http
ufw allow https

# 16. Avvia servizi
echo "🚀 Starting services..."
systemctl daemon-reload
systemctl enable sentinelcore
systemctl start sentinelcore
systemctl reload nginx

# 17. Verifica stato
echo ""
echo "🔍 Checking service status..."
systemctl status sentinelcore --no-pager || true

echo ""
echo "=========================================="
echo "✅ SentinelCore VM Setup Complete!"
echo "=========================================="
echo ""
echo "📝 Important Next Steps:"
echo ""
echo "1. Generate JWT secret:"
echo "   openssl rand -hex 32"
echo ""
echo "2. Edit configuration:"
echo "   sudo nano /opt/sentinelcore/.env"
echo "   - Set VULN_AUTH_SECRET_KEY with the generated secret"
echo "   - Change database password in DATABASE_URL"
echo "   - Set VULN_SECURITY_CORS_ALLOWED_ORIGINS to your domain"
echo ""
echo "3. Update PostgreSQL password:"
echo "   sudo -u postgres psql"
echo "   ALTER USER vlnman WITH PASSWORD 'your_secure_password';"
echo ""
echo "4. Restart service:"
echo "   sudo systemctl restart sentinelcore"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u sentinelcore -f"
echo ""
echo "🌐 Access SentinelCore:"
echo "   http://$(hostname -I | awk '{print $1}')"
echo ""
echo "📊 Default admin credentials:"
echo "   Username: admin"
echo "   Password: admin"
echo "   ⚠️  CHANGE THIS IMMEDIATELY AFTER FIRST LOGIN!"
echo ""
