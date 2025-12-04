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

\`\`\`bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
\`\`\`

### 2. Configure Environment

\`\`\`bash
cp .env.production.example .env
\`\`\`

Edit \`.env\` and set:

\`\`\`bash
# Database
DATABASE_URL=postgresql://sentinelcore:CHANGE_ME@db:5432/sentinelcore
DB_PASSWORD=CHANGE_ME

# JWT Secret (generate with: openssl rand -base64 64)
JWT_SECRET=CHANGE_ME_GENERATE_RANDOM_SECRET

# CORS
CORS_ORIGINS=https://your-domain.com

# Optional: Email notifications
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your-email@gmail.com
SMTP_PASSWORD=your-app-password
\`\`\`

### 3. Start Services

\`\`\`bash
# Build and start all services
docker-compose up -d

# Check logs
docker-compose logs -f

# Check status
docker-compose ps
\`\`\`

### 4. Initialize Database

\`\`\`bash
# Run migrations
docker-compose exec backend ./scripts/migrations.sh

# (Optional) Load test data
docker-compose exec backend ./scripts/populate-database.sh
\`\`\`

### 5. Access Application

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **Default Login:** admin / DogNET2024!

**⚠️ Change default password immediately!**

## Manual Deployment

### 1. Install PostgreSQL

\`\`\`bash
# Ubuntu/Debian
sudo apt update
sudo apt install postgresql-14 postgresql-client-14

# Start service
sudo systemctl start postgresql
sudo systemctl enable postgresql
\`\`\`

### 2. Create Database

\`\`\`bash
sudo -u postgres psql

CREATE DATABASE sentinelcore;
CREATE USER sentinelcore WITH ENCRYPTED PASSWORD 'your_secure_password';
GRANT ALL PRIVILEGES ON DATABASE sentinelcore TO sentinelcore;
ALTER DATABASE sentinelcore OWNER TO sentinelcore;
\q
\`\`\`

### 3. Build Backend

\`\`\`bash
cd vulnerability-manager

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Build release
cargo build --release

# Copy binary
sudo cp target/release/vulnerability-manager /usr/local/bin/
\`\`\`

### 4. Configure Backend

Create \`/etc/sentinelcore/config.yaml\`:

\`\`\`yaml
server:
  host: "0.0.0.0"
  port: 8080

database:
  url: "postgresql://sentinelcore:password@localhost/sentinelcore"
  max_connections: 20

auth:
  secret_key: "YOUR_JWT_SECRET"
  token_expiration_hours: 24

security:
  cors:
    enabled: true
    allowed_origins:
      - "https://your-domain.com"
  rate_limit:
    enabled: true
    requests_per_minute: 60
\`\`\`

### 5. Create Systemd Service

Create \`/etc/systemd/system/sentinelcore.service\`:

\`\`\`ini
[Unit]
Description=SentinelCore Vulnerability Management
After=network.target postgresql.service

[Service]
Type=simple
User=sentinelcore
WorkingDirectory=/opt/sentinelcore
Environment="CONFIG_PATH=/etc/sentinelcore/config.yaml"
Environment="DATABASE_URL=postgresql://sentinelcore:password@localhost/sentinelcore"
ExecStart=/usr/local/bin/vulnerability-manager
Restart=on-failure
RestartSec=10

[Install]
WantedBy=multi-user.target
\`\`\`

Start service:

\`\`\`bash
sudo systemctl daemon-reload
sudo systemctl enable sentinelcore
sudo systemctl start sentinelcore
sudo systemctl status sentinelcore
\`\`\`

### 6. Build Frontend

\`\`\`bash
cd vulnerability-manager-frontend

# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt install -y nodejs

# Build
npm install
npm run build

# Deploy to Nginx
sudo cp -r build/* /var/www/sentinelcore/
\`\`\`

### 7. Configure Nginx

Create \`/etc/nginx/sites-available/sentinelcore\`:

\`\`\`nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com;

    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    
    # Frontend
    location / {
        root /var/www/sentinelcore;
        try_files $uri $uri/ /index.html;
    }

    # Backend API
    location /api/ {
        proxy_pass http://127.0.0.1:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
\`\`\`

Enable site:

\`\`\`bash
sudo ln -s /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
\`\`\`

## Database Setup

### Run Migrations

\`\`\`bash
cd vulnerability-manager
./scripts/migrations.sh
\`\`\`

### Backup Database

\`\`\`bash
# Backup
pg_dump -U sentinelcore sentinelcore > backup_$(date +%Y%m%d).sql

# Restore
psql -U sentinelcore sentinelcore < backup_20240101.sql
\`\`\`

## Configuration

See [SECURITY.md](SECURITY.md) for security-specific configuration.

### Environment Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| DATABASE_URL | PostgreSQL connection string | - | Yes |
| JWT_SECRET | JWT signing secret | - | Yes |
| CORS_ORIGINS | Allowed CORS origins | * | Production |
| SMTP_HOST | SMTP server for emails | - | No |
| LOG_LEVEL | Logging level | info | No |

## Reverse Proxy

SentinelCore should always be behind a reverse proxy (Nginx, Caddy, Traefik) for:

- TLS/SSL termination
- Load balancing
- Rate limiting
- DDoS protection

## Monitoring

### Health Checks

- **Health:** GET /api/health
- **Readiness:** GET /api/ready

### Metrics

Monitor these key metrics:

- Response time (target: <200ms)
- Error rate (target: <1%)
- Database connections
- Memory usage
- CPU usage

### Logging

Logs location:
- Docker: \`docker-compose logs -f\`
- Systemd: \`journalctl -u sentinelcore -f\`
- File: \`/var/log/sentinelcore/app.log\`

## Troubleshooting

### Backend Won't Start

\`\`\`bash
# Check database connection
psql -U sentinelcore -h localhost sentinelcore

# Check configuration
cat /etc/sentinelcore/config.yaml

# Check logs
journalctl -u sentinelcore -n 100
\`\`\`

### Frontend Can't Connect

1. Check CORS configuration
2. Verify API endpoint in frontend config
3. Check network connectivity
4. Inspect browser console for errors

### Database Migration Errors

\`\`\`bash
# Check current version
psql -U sentinelcore sentinelcore -c "SELECT * FROM _sqlx_migrations;"

# Rollback if needed
# Manual intervention required - contact support
\`\`\`

## Updating

### Docker

\`\`\`bash
git pull
docker-compose pull
docker-compose up -d
\`\`\`

### Manual

\`\`\`bash
# Backup first!
pg_dump -U sentinelcore sentinelcore > backup.sql

# Update code
git pull

# Build backend
cd vulnerability-manager
cargo build --release

# Build frontend
cd ../vulnerability-manager-frontend
npm install
npm run build

# Restart services
sudo systemctl restart sentinelcore
sudo systemctl reload nginx
\`\`\`

## Support

For issues, see [GitHub Issues](https://github.com/Dognet-Technologies/sentinelcore/issues).
