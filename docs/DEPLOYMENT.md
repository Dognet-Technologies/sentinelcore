# SentinelCore Deployment Guide

Complete guide for deploying SentinelCore in production environments using native .deb packages.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
- [Method 1: Debian Package (.deb)](#method-1-debian-package-deb)
- [Method 2: Automated VM Setup](#method-2-automated-vm-setup)
- [Database Setup](#database-setup)
- [Configuration](#configuration)
- [Reverse Proxy](#reverse-proxy)
- [Security](#security)
- [Monitoring](#monitoring)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

- **CPU:** 4+ cores recommended
- **RAM:** 8GB minimum, 16GB recommended
- **Storage:** 50GB+ SSD
- **OS:** Debian 12/13 or Ubuntu 22.04/24.04 LTS

### Software Requirements

- PostgreSQL 15+
- Rust 1.75+ with cargo (for building)
- Node.js 20 LTS with npm (for building)
- Nginx or similar reverse proxy
- systemd for service management

## Deployment Methods

SentinelCore offers two native deployment methods:

1. **Debian Package (.deb)** - Build and install via .deb package (recommended for production)
2. **Automated VM Setup** - Script-based installation on fresh Debian 13 VM

## Method 1: Debian Package (.deb)

### Step 1: Clone Repository

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
```

### Step 2: Install Build Dependencies

```bash
sudo apt update
sudo apt install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    postgresql \
    postgresql-contrib \
    nodejs \
    npm \
    curl
```

### Step 3: Install Rust

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"
```

### Step 4: Setup PostgreSQL

```bash
# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Create database and user
sudo -u postgres psql << EOF
CREATE DATABASE vulnerability_manager;
CREATE USER vlnman WITH PASSWORD 'CHANGE_THIS_PASSWORD';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
ALTER DATABASE vulnerability_manager OWNER TO vlnman;
\q
EOF
```

### Step 5: Regenerate SQLx Query Cache

The backend uses SQLx with compile-time query verification. You must regenerate the query cache:

```bash
# Set database URL
export DATABASE_URL="postgresql://vlnman:CHANGE_THIS_PASSWORD@localhost:5432/vulnerability_manager"

# Run regeneration script
scripts/deployment/regenerate-sqlx-cache.sh
```

This will:
- Verify PostgreSQL connection
- Run all database migrations
- Generate SQLx query cache in \`vulnerability-manager/.sqlx/\`

### Step 6: Build .deb Package

```bash
scripts/deployment/build-deb.sh
```

This will:
- Compile Rust backend (using SQLx offline mode with cache)
- Build React frontend
- Create .deb package
- Output: \`/tmp/sentinelcore_1.0.0_amd64.deb\`

### Step 7: Install Package

```bash
sudo dpkg -i /tmp/sentinelcore_1.0.0_amd64.deb
sudo apt --fix-broken install  # If needed
```

### Step 8: Configure

```bash
sudo nano /opt/sentinelcore/.env

# Minimum configuration:
DATABASE_URL=postgresql://vlnman:CHANGE_PASSWORD@localhost:5432/vulnerability_manager
JWT_SECRET=$(openssl rand -base64 64)
VULN_SERVER_HOST=0.0.0.0
VULN_SERVER_PORT=8080
```

### Step 9: Start Service

```bash
sudo systemctl start sentinelcore
sudo systemctl enable sentinelcore
sudo systemctl status sentinelcore
```

## Method 2: Automated VM Setup

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
sudo scripts/deployment/vm-setup-debian13.sh
```

Automated script installs all dependencies and configures the system.

## See Full Documentation

For complete configuration, security hardening, monitoring, and troubleshooting:
- Full deployment guide: \`docs/DEPLOYMENT.md\`
- API documentation: \`docs/API.md\`
- Security guide: \`docs/SECURITY.md\`
- Scanner integration: \`docs/SCANNER_INTEGRATION.md\`
