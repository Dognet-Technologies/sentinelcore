# SentinelCore - Production Security Setup Guide

## 🔒 Critical Security Configuration

This guide walks you through securing SentinelCore for production deployment.

---

## 1. Generate Strong Secrets

### JWT Secret

```bash
# Generate a strong 64-byte random secret
openssl rand -base64 64

# Or use this one-liner to generate and save
echo "JWT_SECRET=$(openssl rand -base64 64)" > .env.production
```

### Database Password

```bash
# Generate a strong database password
openssl rand -base64 32

# Update DATABASE_URL in .env.production
# Format: postgresql://username:PASSWORD@host:port/database
```

---

## 2. Configure Environment Variables

### Copy the example file

```bash
cp .env.production.example .env.production
```

### Edit .env.production with your values

**CRITICAL CHANGES REQUIRED:**
1. `JWT_SECRET` - Replace with generated secret
2. `DATABASE_URL` - Update password
3. `VULN_SECURITY_CORS_ALLOWED_ORIGINS` - Set your actual domain(s)
4. `VULN_SECURITY_COOKIES_DOMAIN` - Set your domain
5. `VULN_SERVER_TLS_CERT_PATH` - Path to your TLS certificate
6. `VULN_SERVER_TLS_KEY_PATH` - Path to your TLS private key

---

## 3. TLS/HTTPS Certificate Setup

### Option A: Let's Encrypt (Recommended for production)

```bash
# Install certbot
sudo apt-get install certbot

# Generate certificate
sudo certbot certonly --standalone -d sentinelcore.example.com

# Certificates will be in:
# /etc/letsencrypt/live/sentinelcore.example.com/fullchain.pem
# /etc/letsencrypt/live/sentinelcore.example.com/privkey.pem

# Update .env.production:
VULN_SERVER_TLS_CERT_PATH=/etc/letsencrypt/live/sentinelcore.example.com/fullchain.pem
VULN_SERVER_TLS_KEY_PATH=/etc/letsencrypt/live/sentinelcore.example.com/privkey.pem
```

### Option B: Self-Signed Certificate (Development/Testing Only)

```bash
# Generate self-signed certificate (valid for 365 days)
openssl req -x509 -newkey rsa:4096 -nodes \
  -keyout key.pem -out cert.pem -days 365 \
  -subj "/CN=sentinelcore.example.com"

# Move certificates to secure location
sudo mkdir -p /etc/sentinelcore/certs
sudo mv cert.pem key.pem /etc/sentinelcore/certs/
sudo chmod 600 /etc/sentinelcore/certs/key.pem
sudo chmod 644 /etc/sentinelcore/certs/cert.pem
```

---

## 4. Database Security

### Create Production Database User

```sql
-- Connect to PostgreSQL as superuser
sudo -u postgres psql

-- Create strong password user
CREATE USER vlnman WITH PASSWORD 'your_strong_generated_password';

-- Create database
CREATE DATABASE vulnerability_manager OWNER vlnman;

-- Grant privileges
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;

-- Enable SSL connections (recommended)
-- Edit postgresql.conf:
ssl = on
ssl_cert_file = '/path/to/server-cert.pem'
ssl_key_file = '/path/to/server-key.pem'
```

### Update Connection String

```bash
# In .env.production
DATABASE_URL=postgresql://vlnman:your_strong_generated_password@localhost:5432/vulnerability_manager?sslmode=require
```

---

## 5. File System Security

### Create Required Directories

```bash
# Application directories
sudo mkdir -p /var/lib/sentinelcore/plugins
sudo mkdir -p /var/log/sentinelcore
sudo mkdir -p /etc/sentinelcore/certs

# Set ownership (replace 'sentinelcore' with your application user)
sudo chown -R sentinelcore:sentinelcore /var/lib/sentinelcore
sudo chown -R sentinelcore:sentinelcore /var/log/sentinelcore
sudo chown -R sentinelcore:sentinelcore /etc/sentinelcore

# Set permissions
sudo chmod 750 /var/lib/sentinelcore
sudo chmod 750 /var/log/sentinelcore
sudo chmod 750 /etc/sentinelcore
sudo chmod 600 /etc/sentinelcore/certs/key.pem
```

---

## 6. Firewall Configuration

```bash
# Allow HTTPS traffic
sudo ufw allow 443/tcp

# Allow metrics port (only from monitoring systems)
sudo ufw allow from MONITORING_IP to any port 9090

# Enable firewall
sudo ufw enable
```

---

## 7. CORS Configuration

Update `VULN_SECURITY_CORS_ALLOWED_ORIGINS` in `.env.production`:

```bash
# Single domain
VULN_SECURITY_CORS_ALLOWED_ORIGINS=https://sentinelcore.example.com

# Multiple domains (comma-separated)
VULN_SECURITY_CORS_ALLOWED_ORIGINS=https://sentinelcore.example.com,https://app.sentinelcore.example.com
```

---

## 8. Validate Configuration

### Before starting the application:

```bash
# Check that secrets are changed from defaults
grep -E "DogNET|CHANGE_THIS" .env.production && echo "⚠️  WARNING: Default secrets detected!" || echo "✅ Secrets look good"

# Verify TLS certificates exist
ls -l /etc/sentinelcore/certs/

# Test database connection
psql $DATABASE_URL -c "SELECT version();"
```

---

## 9. Application Startup

### Set environment

```bash
export APP_ENV=production
export RUST_LOG=info
```

### Run with production config

```bash
# Load production environment
source .env.production

# Start application
./vulnerability-manager
```

---

## 10. Post-Deployment Security Checklist

- [ ] JWT_SECRET changed from default "DogNET"
- [ ] Database password changed from default
- [ ] CORS origins set to actual domain(s)
- [ ] TLS/HTTPS enabled with valid certificate
- [ ] Cookies configured as secure + httpOnly
- [ ] Security headers enabled
- [ ] Rate limiting enabled
- [ ] CSRF protection enabled
- [ ] Firewall rules configured
- [ ] Application user created (non-root)
- [ ] File permissions set correctly
- [ ] Logs directory writable by app user
- [ ] Database SSL connection enabled
- [ ] .env.production NOT committed to git
- [ ] Health check endpoint responding
- [ ] Metrics endpoint secured

---

## 11. Secrets Management (Recommended)

For production environments, use a proper secrets manager:

### HashiCorp Vault Example

```bash
# Store JWT secret
vault kv put secret/sentinelcore jwt_secret="$(openssl rand -base64 64)"

# Store database password
vault kv put secret/sentinelcore db_password="$(openssl rand -base64 32)"

# Retrieve at runtime
export JWT_SECRET=$(vault kv get -field=jwt_secret secret/sentinelcore)
export DATABASE_URL="postgresql://vlnman:$(vault kv get -field=db_password secret/sentinelcore)@localhost/vulnerability_manager"
```

### AWS Secrets Manager Example

```bash
# Store secrets
aws secretsmanager create-secret \
  --name sentinelcore/jwt-secret \
  --secret-string "$(openssl rand -base64 64)"

# Retrieve at runtime
export JWT_SECRET=$(aws secretsmanager get-secret-value \
  --secret-id sentinelcore/jwt-secret \
  --query SecretString \
  --output text)
```

---

## 12. Monitoring and Logging

### View application logs

```bash
tail -f /var/log/sentinelcore/app.log
```

### Check metrics

```bash
curl http://localhost:9090/metrics
```

### Health check

```bash
curl https://sentinelcore.example.com/health
```

---

## 🚨 Security Warnings

1. **NEVER commit .env.production to git**
2. **NEVER use default secrets in production**
3. **ALWAYS use HTTPS in production**
4. **ALWAYS use httpOnly cookies**
5. **ALWAYS validate CORS origins**
6. **ALWAYS enable rate limiting**
7. **ALWAYS use strong database passwords**
8. **ALWAYS run as non-root user**
9. **ALWAYS keep dependencies updated**
10. **ALWAYS monitor security logs**

---

## Support

For security issues, contact: security@sentinelcore.example.com

Last updated: 2025-12-04
