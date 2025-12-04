# SentinelCore Deployment Guide

Complete guide for deploying SentinelCore in production environments.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Docker Deployment](#docker-deployment)
- [Manual Deployment](#manual-deployment)
- [Database Setup](#database-setup)
- [Configuration](#configuration)
- [Reverse Proxy](#reverse-proxy)
- [Monitoring](#monitoring)

## Prerequisites

### System Requirements

- **CPU:** 4+ cores recommended
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 50GB+ SSD
- **OS:** Linux (Ubuntu 22.04 LTS recommended)

### Software Requirements

**Option 1: Docker** (Recommended)
- Docker Engine 24.0+
- Docker Compose 2.0+

**Option 2: Manual**
- PostgreSQL 14+
- Rust 1.75+ with cargo
- Node.js 18+ with npm
- Nginx or similar reverse proxy

## Docker Deployment

### 1. Clone Repository

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
```

### 2. Configure Environment

```bash
cp .env.production.example .env
```

Edit `.env` and set **CRITICAL** secrets:

```bash
# Generate strong password
openssl rand -base64 32

# Generate JWT secret
openssl rand -base64 64
```

Update `.env`:

```bash
# Database (matches docker-compose.yml)
DATABASE_URL=postgresql://vlnman:YOUR_STRONG_PASSWORD@database:5432/vulnerability_manager
DB_PASSWORD=YOUR_STRONG_PASSWORD

# JWT Secret - MUST BE CHANGED
JWT_SECRET=YOUR_GENERATED_SECRET_AT_LEAST_64_CHARS

# CORS - Your frontend URL
VULN_SECURITY_CORS_ALLOWED_ORIGINS=https://your-domain.com

# Optional: Email notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
```

**⚠️ NEVER use default passwords in production!**

### 3. Start Services

```bash
# Build and start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Check status
docker-compose ps
```

### 4. Initialize Database

The database will be initialized automatically on first start with migrations in `vulnerability-manager/migrations/`.

To verify:

```bash
# Check database is ready
docker-compose exec database psql -U vlnman -d vulnerability_manager -c "SELECT COUNT(*) FROM users;"
```

### 5. Access Application

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **Metrics:** http://localhost:9090
- **Default Login:** admin / DogNET2024!

**⚠️ Change default password immediately after first login!**

### 6. Change Default Password

```bash
# Use the provided script
./scripts/change-password.sh admin

# Or via API
curl -X PUT http://localhost:8080/api/users/me/password \
  -H "Content-Type: application/json" \
  -H "Cookie: auth_token=YOUR_TOKEN" \
  -d '{"current_password":"DogNET2024!","new_password":"YourNewSecurePassword123!"}'
```

## Manual Deployment

### 1. Install PostgreSQL

```bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-14 postgresql-client-14

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### 2. Create Database

```bash
sudo -u postgres psql

CREATE DATABASE vulnerability_manager;
CREATE USER vlnman WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
ALTER DATABASE vulnerability_manager OWNER TO vlnman;
\q
```

### 3. Build Backend

```bash
cd vulnerability-manager

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Build release
cargo build --release

# Copy binary
sudo cp target/release/vulnerability-manager /usr/local/bin/
```

### 4. Configure Backend

Create `/etc/sentinelcore/config.yaml`:

```yaml
server:
  host: "0.0.0.0"
  port: 8080

database:
  url: "postgresql://vlnman:password@localhost/vulnerability_manager"
  max_connections: 20

auth:
  secret_key: "YOUR_JWT_SECRET_64_CHARS_MINIMUM"
  token_expiration_hours: 24

security:
  cors:
    enabled: true
    allowed_origins:
      - "https://your-domain.com"
  cookies:
    secure: true
    http_only: true
    same_site: "Strict"
    domain: "your-domain.com"
  rate_limit:
    enabled: true
    requests_per_minute: 60
    burst_size: 100
  headers:
    hsts_max_age_seconds: 31536000
    hsts_include_subdomains: true
    hsts_preload: true
    frame_options: "DENY"
    content_type_options: "nosniff"
    xss_protection: "1; mode=block"
    referrer_policy: "strict-origin-when-cross-origin"
    csp: "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline';"
```

### 5. Run Migrations

```bash
cd vulnerability-manager

# Set DATABASE_URL
export DATABASE_URL="postgresql://vlnman:password@localhost/vulnerability_manager"

# Run migrations using the script
../scripts/migrations.sh
```

### 6. Create Systemd Service

Create `/etc/systemd/system/sentinelcore.service`:

```ini
[Unit]
Description=SentinelCore Vulnerability Management
After=network.target postgresql.service

[Service]
Type=simple
User=sentinelcore
Group=sentinelcore
WorkingDirectory=/opt/sentinelcore
Environment="CONFIG_PATH=/etc/sentinelcore/config.yaml"
Environment="DATABASE_URL=postgresql://vlnman:password@localhost/vulnerability_manager"
ExecStart=/usr/local/bin/vulnerability-manager
Restart=on-failure
RestartSec=10

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/sentinelcore
ReadWritePaths=/var/log/sentinelcore

[Install]
WantedBy=multi-user.target
```

Start service:

```bash
# Create user
sudo useradd -r -s /bin/false sentinelcore

# Create directories
sudo mkdir -p /opt/sentinelcore
sudo mkdir -p /var/lib/sentinelcore
sudo mkdir -p /var/log/sentinelcore
sudo chown -R sentinelcore:sentinelcore /opt/sentinelcore /var/lib/sentinelcore /var/log/sentinelcore

# Enable and start
sudo systemctl daemon-reload
sudo systemctl enable sentinelcore
sudo systemctl start sentinelcore
sudo systemctl status sentinelcore
```

### 7. Build Frontend

```bash
cd vulnerability-manager-frontend

# Install Node.js (if not installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Configure API endpoint
cat > .env.production << EOF
REACT_APP_API_URL=https://your-domain.com/api
EOF

# Build
npm install
npm run build

# Deploy to Nginx
sudo cp -r build/* /var/www/sentinelcore/
```

## Configuration

### Environment Variables

Key environment variables for production:

```bash
# Database
DATABASE_URL=postgresql://vlnman:PASSWORD@localhost:5432/vulnerability_manager
VULN_DATABASE_MAX_CONNECTIONS=20

# Authentication
JWT_SECRET=your_64_char_secret

# Server
VULN_SERVER_HOST=0.0.0.0
VULN_SERVER_PORT=8080
VULN_SERVER_ENABLE_TLS=true

# Security
VULN_SECURITY_CORS_ALLOWED_ORIGINS=https://your-domain.com
VULN_SECURITY_RATE_LIMIT_ENABLED=true
VULN_SECURITY_RATE_LIMIT_REQUESTS_PER_MINUTE=60

# Logging
RUST_LOG=info
VULN_LOG_LEVEL=info
VULN_LOG_FORMAT=json

# Application
APP_ENV=production
```

### Security Configuration

See [SECURITY.md](SECURITY.md) for detailed security hardening instructions including:
- TLS/SSL setup
- Security headers configuration
- CORS whitelist
- Rate limiting tuning
- Cookie security settings

## Reverse Proxy

### Nginx Configuration

Create `/etc/nginx/sites-available/sentinelcore`:

```nginx
upstream backend {
    server localhost:8080;
    keepalive 64;
}

upstream frontend {
    server localhost:3000;
    keepalive 64;
}

# Redirect HTTP to HTTPS
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

# HTTPS Server
server {
    listen 443 ssl http2;
    server_name your-domain.com;

    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;
    ssl_prefer_server_ciphers on;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
    add_header X-Frame-Options "DENY" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # API Backend
    location /api/ {
        proxy_pass http://backend/api/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }

    # Frontend
    location / {
        proxy_pass http://frontend/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }

    # Metrics (restrict access)
    location /metrics {
        proxy_pass http://localhost:9090/metrics;
        allow 10.0.0.0/8;  # Internal network
        deny all;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### SSL/TLS with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot --nginx -d your-domain.com

# Auto-renewal (already configured by certbot)
sudo systemctl status certbot.timer
```

## Monitoring

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health

# Frontend health
curl http://localhost:3000/

# Database health
docker-compose exec database pg_isready -U vlnman -d vulnerability_manager
```

### Prometheus Metrics

Metrics are exposed on port 9090:

```bash
curl http://localhost:9090/metrics
```

### Logs

```bash
# Docker logs
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f database

# System logs
sudo journalctl -u sentinelcore -f
```

### Container Status

```bash
# Check all containers
docker-compose ps

# Check specific service
docker-compose ps backend

# View resource usage
docker stats sentinelcore-backend sentinelcore-frontend sentinelcore-db
```

## Backup and Recovery

### Database Backup

```bash
# Create backup
docker-compose exec database pg_dump -U vlnman vulnerability_manager > backup-$(date +%Y%m%d).sql

# Restore from backup
docker-compose exec -T database psql -U vlnman vulnerability_manager < backup-20240101.sql
```

### Full Backup

```bash
# Backup script
./scripts/backup.sh

# Includes:
# - Database dump
# - Uploaded files
# - Configuration files
# - Plugin data
```

## Troubleshooting

### Backend won't start

```bash
# Check logs
docker-compose logs backend

# Common issues:
# 1. Database not ready - wait for healthcheck
# 2. JWT_SECRET not set - check .env
# 3. Port already in use - check netstat -tlnp | grep 8080
```

### Frontend can't connect to backend

```bash
# Check CORS configuration
# Verify VULN_SECURITY_CORS_ALLOWED_ORIGINS in .env

# Check network connectivity
docker-compose exec frontend curl http://backend:8080/api/health
```

### Database connection errors

```bash
# Verify database is running
docker-compose ps database

# Check credentials
docker-compose exec database psql -U vlnman -d vulnerability_manager

# Check DATABASE_URL format
echo $DATABASE_URL
```

## Upgrade Procedure

```bash
# 1. Backup current data
./scripts/backup.sh

# 2. Pull latest changes
git pull origin main

# 3. Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d

# 4. Run migrations (if needed)
docker-compose exec backend ./migrations.sh

# 5. Verify deployment
docker-compose ps
curl http://localhost:8080/api/health
```

## Support

- 📖 Documentation: [GitHub Wiki](https://github.com/Dognet-Technologies/sentinelcore/wiki)
- 🐛 Issues: [GitHub Issues](https://github.com/Dognet-Technologies/sentinelcore/issues)
- 📧 Email: support@dognet-technologies.com

---

**Made with ❤️ by Dognet Technologies**
