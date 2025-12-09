#!/bin/bash
# Script per creare pacchetto .deb di SentinelCore
# Compatibile con Debian 12/13 e Ubuntu 22.04/24.04

set -e

VERSION="1.0.0"
ARCH="amd64"
PKG_NAME="sentinelcore"
BUILD_DIR="/tmp/${PKG_NAME}-${VERSION}"
DEB_DIR="${BUILD_DIR}/DEBIAN"

echo "🔨 Building SentinelCore .deb package v${VERSION}"

# Pulisci build precedenti
rm -rf "${BUILD_DIR}"
mkdir -p "${DEB_DIR}"

# 1. Compila il backend Rust
echo "📦 Compiling Rust backend..."
cd vulnerability-manager

# Enable SQLx offline mode with existing query cache
export SQLX_OFFLINE=true

# Verify .sqlx cache exists
if [ ! -d ".sqlx" ]; then
    echo "❌ Error: SQLx query cache (.sqlx/) not found!"
    echo "Run 'cargo sqlx prepare' first with a PostgreSQL connection"
    exit 1
fi

echo "✅ Using SQLx query cache from .sqlx/ directory"

# Build with offline mode
if ! cargo build --release 2>&1; then
    echo ""
    echo "❌ Build failed!"
    echo ""
    echo "If you see 'no cached data for this query' errors, the SQLx cache is outdated."
    echo ""
    echo "To fix this, regenerate the cache:"
    echo "   scripts/deployment/regenerate-sqlx-cache.sh"
    echo ""
    echo "This requires PostgreSQL to be running. See scripts/deployment/regenerate-sqlx-cache.sh for details."
    echo ""
    exit 1
fi

cd ..

# 2. Compila il frontend React
echo "🎨 Building React frontend..."
cd vulnerability-manager-frontend
npm install
npm run build
cd ..

# 3. Crea struttura directory per il pacchetto
echo "📁 Creating package structure..."
mkdir -p "${BUILD_DIR}/opt/sentinelcore/bin"
mkdir -p "${BUILD_DIR}/opt/sentinelcore/frontend"
mkdir -p "${BUILD_DIR}/opt/sentinelcore/config"
mkdir -p "${BUILD_DIR}/opt/sentinelcore/migrations"
mkdir -p "${BUILD_DIR}/etc/systemd/system"
mkdir -p "${BUILD_DIR}/var/lib/sentinelcore/uploads"
mkdir -p "${BUILD_DIR}/var/log/sentinelcore"

# 4. Copia i file compilati
echo "📋 Copying compiled files..."
cp vulnerability-manager/target/release/vulnerability-manager "${BUILD_DIR}/opt/sentinelcore/bin/"
cp -r vulnerability-manager-frontend/build/* "${BUILD_DIR}/opt/sentinelcore/frontend/"
cp -r vulnerability-manager/config/* "${BUILD_DIR}/opt/sentinelcore/config/"
cp -r vulnerability-manager/migrations "${BUILD_DIR}/opt/sentinelcore/"
cp .env.production.example "${BUILD_DIR}/opt/sentinelcore/.env.example"

# 5. Crea file control
cat > "${DEB_DIR}/control" << EOF
Package: ${PKG_NAME}
Version: ${VERSION}
Section: utils
Priority: optional
Architecture: ${ARCH}
Depends: postgresql (>= 15), nginx (>= 1.18), libpq5, libssl3
Maintainer: Dognet Technologies <info@dognet.tech>
Description: SentinelCore - Enterprise Vulnerability Management System
 Complete vulnerability management platform with:
 - Network discovery and mapping
 - Multi-scanner integration (Nessus, Qualys, OpenVAS)
 - Team collaboration and workflow
 - Compliance reporting (PCI-DSS, ISO 27001, GDPR)
 - Real-time dashboard and analytics
EOF

# 6. Crea script postinst (post-installazione)
cat > "${DEB_DIR}/postinst" << 'EOF'
#!/bin/bash
set -e

# Crea utente sentinelcore se non esiste
if ! id -u sentinelcore > /dev/null 2>&1; then
    useradd -r -s /bin/false -d /opt/sentinelcore sentinelcore
fi

# Imposta permessi
chown -R sentinelcore:sentinelcore /opt/sentinelcore
chown -R sentinelcore:sentinelcore /var/lib/sentinelcore
chown -R sentinelcore:sentinelcore /var/log/sentinelcore
chmod 755 /opt/sentinelcore/bin/vulnerability-manager

# Crea database PostgreSQL se non esiste
if sudo -u postgres psql -lqt | cut -d \| -f 1 | grep -qw vulnerability_manager; then
    echo "Database already exists, skipping creation"
else
    sudo -u postgres psql << PSQL
CREATE DATABASE vulnerability_manager;
CREATE USER vlnman WITH PASSWORD 'changeme';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
PSQL

    # Esegui migrations
    echo "Running database migrations..."
    for sql_file in /opt/sentinelcore/migrations/*.sql; do
        sudo -u postgres psql -d vulnerability_manager -f "$sql_file"
    done
fi

# Crea file .env da template se non esiste
if [ ! -f /opt/sentinelcore/.env ]; then
    cp /opt/sentinelcore/.env.example /opt/sentinelcore/.env
    echo "⚠️  IMPORTANT: Edit /opt/sentinelcore/.env and set your secrets!"
fi

# Crea servizio systemd
cat > /etc/systemd/system/sentinelcore.service << SERVICE
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
ExecStart=/opt/sentinelcore/bin/vulnerability-manager
Restart=always
RestartSec=10

# Hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/sentinelcore /var/log/sentinelcore

[Install]
WantedBy=multi-user.target
SERVICE

# Configura nginx
if [ -f /etc/nginx/sites-available/default ]; then
    cat > /etc/nginx/sites-available/sentinelcore << 'NGINX'
server {
    listen 80;
    server_name _;

    # Frontend
    location / {
        root /opt/sentinelcore/frontend;
        try_files $uri $uri/ /index.html;
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
    }
}
NGINX

    ln -sf /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/
    nginx -t && systemctl reload nginx
fi

# Ricarica systemd e avvia servizio
systemctl daemon-reload
systemctl enable sentinelcore
systemctl start sentinelcore

echo ""
echo "✅ SentinelCore installed successfully!"
echo ""
echo "📝 Next steps:"
echo "1. Edit configuration: sudo nano /opt/sentinelcore/.env"
echo "2. Set JWT_SECRET and DB_PASSWORD"
echo "3. Restart service: sudo systemctl restart sentinelcore"
echo "4. Check status: sudo systemctl status sentinelcore"
echo "5. View logs: sudo journalctl -u sentinelcore -f"
echo ""
echo "🌐 Access SentinelCore at: http://YOUR_SERVER_IP"
echo ""
EOF

chmod 755 "${DEB_DIR}/postinst"

# 7. Crea script prerm (pre-rimozione)
cat > "${DEB_DIR}/prerm" << 'EOF'
#!/bin/bash
set -e

# Ferma servizio
systemctl stop sentinelcore || true
systemctl disable sentinelcore || true
EOF

chmod 755 "${DEB_DIR}/prerm"

# 8. Costruisci il pacchetto .deb
echo "🏗️  Building .deb package..."
dpkg-deb --build "${BUILD_DIR}" "${PKG_NAME}_${VERSION}_${ARCH}.deb"

# 9. Cleanup
rm -rf "${BUILD_DIR}"

echo ""
echo "✅ Package created: ${PKG_NAME}_${VERSION}_${ARCH}.deb"
echo ""
echo "📦 Install with:"
echo "   sudo dpkg -i ${PKG_NAME}_${VERSION}_${ARCH}.deb"
echo "   sudo apt-get install -f  # If there are missing dependencies"
echo ""
