# SentinelCore - Docker Deployment Guide

Complete guide for deploying SentinelCore using Docker and Docker Compose.

---

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+
- At least 4GB RAM
- 10GB disk space

---

## Quick Start

### 1. Clone and Configure

```bash
# Clone repository
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore

# Copy environment template
cp .env.production.example .env.production

# Generate secrets
echo "JWT_SECRET=$(openssl rand -base64 64)" >> .env.production
echo "DB_PASSWORD=$(openssl rand -base64 32)" >> .env.production
```

### 2. Edit .env.production

```bash
# Required: Set your domain(s) for CORS
CORS_ALLOWED_ORIGINS=https://sentinelcore.example.com,https://app.sentinelcore.example.com

# Required: JWT secret (generated above)
JWT_SECRET=your_generated_secret_here

# Required: Database password (generated above)
DB_PASSWORD=your_generated_password_here

# Optional: API URL for frontend
API_URL=https://sentinelcore.example.com/api

# Optional: Enable TLS
ENABLE_TLS=false

# Optional: Logging
RUST_LOG=info
```

### 3. Build and Run

```bash
# Build images
docker-compose build

# Start services
docker-compose up -d

# Check status
docker-compose ps

# View logs
docker-compose logs -f
```

### 4. Initialize Database

```bash
# Run migrations
docker-compose exec backend /app/vulnerability-manager migrate

# Or manually connect to database
docker-compose exec database psql -U vlnman -d vulnerability_manager
```

### 5. Access the Application

- Frontend: http://localhost:3000
- Backend API: http://localhost:8080
- API Health Check: http://localhost:8080/api/health
- Metrics: http://localhost:9090/metrics

---

## Service Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │
       ▼
┌─────────────────┐     ┌──────────────┐
│   Frontend      │────▶│   Backend    │
│   (Nginx)       │     │   (Rust)     │
│   Port 3000     │     │   Port 8080  │
└─────────────────┘     └──────┬───────┘
                               │
                               ▼
                        ┌──────────────┐
                        │  PostgreSQL  │
                        │   Port 5432  │
                        └──────────────┘
```

---

## Production Deployment

### With TLS/HTTPS

1. **Obtain SSL Certificates**

```bash
# Using Let's Encrypt
sudo certbot certonly --standalone -d sentinelcore.example.com

# Certificates will be in:
# /etc/letsencrypt/live/sentinelcore.example.com/
```

2. **Copy Certificates**

```bash
mkdir -p certs
sudo cp /etc/letsencrypt/live/sentinelcore.example.com/fullchain.pem certs/cert.pem
sudo cp /etc/letsencrypt/live/sentinelcore.example.com/privkey.pem certs/key.pem
sudo chown $USER:$USER certs/*.pem
```

3. **Enable TLS in .env.production**

```bash
ENABLE_TLS=true
VULN_SERVER_TLS_CERT_PATH=/etc/sentinelcore/certs/cert.pem
VULN_SERVER_TLS_KEY_PATH=/etc/sentinelcore/certs/key.pem
```

4. **Update docker-compose.yml volumes**

```yaml
backend:
  volumes:
    - ./certs:/etc/sentinelcore/certs:ro
```

5. **Restart services**

```bash
docker-compose down
docker-compose up -d
```

---

## Using Reverse Proxy

For production, use the included Nginx reverse proxy:

### 1. Create nginx-proxy.conf

```nginx
events {
    worker_connections 1024;
}

http {
    upstream backend {
        server backend:8080;
    }

    upstream frontend {
        server frontend:80;
    }

    server {
        listen 443 ssl http2;
        server_name sentinelcore.example.com;

        ssl_certificate /etc/nginx/certs/cert.pem;
        ssl_certificate_key /etc/nginx/certs/key.pem;

        # Security headers
        add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;
        add_header X-Frame-Options "DENY" always;
        add_header X-Content-Type-Options "nosniff" always;

        # API requests
        location /api/ {
            proxy_pass http://backend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }

        # Frontend
        location / {
            proxy_pass http://frontend;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
        }
    }

    # Redirect HTTP to HTTPS
    server {
        listen 80;
        server_name sentinelcore.example.com;
        return 301 https://$server_name$request_uri;
    }
}
```

### 2. Start with proxy profile

```bash
docker-compose --profile with-proxy up -d
```

---

## Maintenance

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f backend
docker-compose logs -f frontend
docker-compose logs -f database
```

### Database Backup

```bash
# Create backup
docker-compose exec database pg_dump -U vlnman vulnerability_manager > backup_$(date +%Y%m%d).sql

# Restore backup
docker-compose exec -T database psql -U vlnman vulnerability_manager < backup_20231204.sql
```

### Update Services

```bash
# Pull latest code
git pull

# Rebuild and restart
docker-compose build
docker-compose up -d

# Or zero-downtime rolling update
docker-compose up -d --no-deps --build backend
docker-compose up -d --no-deps --build frontend
```

### Scale Services

```bash
# Scale backend replicas
docker-compose up -d --scale backend=3

# View scaled services
docker-compose ps
```

---

## Monitoring

### Health Checks

```bash
# Backend health
curl http://localhost:8080/api/health

# Frontend health
curl http://localhost:3000/

# Database health
docker-compose exec database pg_isready -U vlnman
```

### Metrics

Access Prometheus-compatible metrics:

```bash
curl http://localhost:9090/metrics
```

### Resource Usage

```bash
# Container stats
docker stats

# Specific service
docker stats sentinelcore-backend
```

---

## Troubleshooting

### Services Won't Start

```bash
# Check logs
docker-compose logs

# Check configuration
docker-compose config

# Validate environment
docker-compose exec backend env | grep VULN_
```

### Database Connection Issues

```bash
# Test database connection
docker-compose exec backend psql -h database -U vlnman -d vulnerability_manager

# Check database logs
docker-compose logs database
```

### Backend Returns 500 Errors

```bash
# Check backend logs
docker-compose logs backend

# Verify secrets are set
docker-compose exec backend env | grep JWT_SECRET

# Test database connectivity
docker-compose exec backend curl -f http://localhost:8080/api/health
```

### Frontend Can't Reach API

1. Check CORS configuration:
   ```bash
   # Verify CORS origins
   docker-compose exec backend env | grep CORS_ALLOWED_ORIGINS
   ```

2. Check API_URL in frontend:
   ```bash
   docker-compose exec frontend cat /usr/share/nginx/html/index.html | grep API_URL
   ```

3. Verify network connectivity:
   ```bash
   docker-compose exec frontend curl -f http://backend:8080/api/health
   ```

---

## Security Checklist

- [ ] JWT_SECRET changed from default
- [ ] DB_PASSWORD is strong and unique
- [ ] CORS_ALLOWED_ORIGINS set to actual domain(s)
- [ ] TLS/HTTPS enabled with valid certificates
- [ ] Database port not exposed publicly (only localhost)
- [ ] Services running as non-root users
- [ ] Docker images updated regularly
- [ ] Firewall configured (only 80, 443 open)
- [ ] Regular backups scheduled
- [ ] Monitoring and alerting configured

---

## Performance Tuning

### Database

```yaml
database:
  command:
    - postgres
    - -c
    - max_connections=200
    - -c
    - shared_buffers=256MB
    - -c
    - effective_cache_size=1GB
```

### Backend

```yaml
backend:
  environment:
    VULN_DATABASE_MAX_CONNECTIONS: 50
  deploy:
    resources:
      limits:
        cpus: '2'
        memory: 2G
      reservations:
        cpus: '1'
        memory: 1G
```

---

## Support

For issues or questions:
- GitHub Issues: https://github.com/Dognet-Technologies/sentinelcore/issues
- Documentation: /docs
- Security: security@sentinelcore.example.com

---

Last updated: 2025-12-04
