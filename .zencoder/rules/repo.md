---
description: Repository Information Overview
alwaysApply: true
---

# SentinelCore Repository Information

## Repository Summary

SentinelCore is an enterprise vulnerability management platform with complete feature implementation for tracking, prioritizing, and remediating security vulnerabilities. The monorepo contains three main components: a Rust backend, TypeScript React frontend, and infrastructure provisioning via Packer.

## Repository Structure

- **vulnerability-manager/**: Backend service (Rust with Axum)
- **vulnerability-manager-frontend/**: Web UI (React with TypeScript)
- **packer/**: VM image builder (HashiCorp Packer)
- **scripts/**: Deployment and installation scripts
- **docs/**: Comprehensive documentation
- **migrations/**: PostgreSQL database migrations

### Main Repository Components

- **Rust Backend**: REST API for vulnerability management, authentication, team collaboration, notifications, scanner integration, and network discovery
- **React Frontend**: Dashboard, vulnerability management UI, risk scoring, SLA tracking, and team collaboration features
- **Database**: PostgreSQL 15+ with 16+ migrations for schema management
- **Infrastructure**: Packer-based VM provisioning for VirtualBox and QEMU/KVM

## Projects

### Vulnerability Manager (Backend)

**Configuration File**: `vulnerability-manager/Cargo.toml`

#### Language & Runtime

**Language**: Rust  
**Edition**: 2021  
**Version**: 1.75+  
**Build System**: Cargo  
**Package Manager**: Cargo

#### Dependencies

**Main Dependencies**:
- Axum 0.6 (async web framework)
- SQLx 0.7 (SQL queries with compile-time checking)
- Tokio 1.28 (async runtime with full features)
- Tower 0.4 (middleware and service composition)
- PostgreSQL driver with native-tls
- Serde 1.0 (serialization/deserialization)
- JsonWebToken 9.0 (JWT authentication)
- Argon2 0.5 (password hashing)
- Tracing 0.1 (structured logging)
- SQLx with features: postgres, uuid, chrono, json, macros, ipnetwork, bigdecimal

**Development Dependencies**:
- Quick-xml 0.31 (XML parsing for scanner reports)
- CSV 1.3 (CSV export)
- Reqwest 0.11 (HTTP client)
- Lettre 0.11 (email notifications)
- Flate2 1.0 (compression)

#### Build & Installation

```bash
cd vulnerability-manager
cargo build --release
cargo run
```

#### Database

**Type**: PostgreSQL 15+  
**Migrations**: 16+ SQLx migrations in `migrations/` directory  
**Features**: JSONB, full-text search, triggers, custom functions, audit logging

#### Configuration

**File**: `config/default.yaml`  
**Environment Variables**: `.env` file (copy from `.env.example`)

Key settings:
- Server host/port (default: 0.0.0.0:8080)
- Database connection pool (max 5 connections)
- JWT secret and token duration
- Password policy validation
- Network scanning interface and timeout
- Plugin directory configuration

#### Entry Point

**Main**: `src/main.rs` - Server initialization and route setup

---

### Vulnerability Manager Frontend

**Configuration File**: `vulnerability-manager-frontend/package.json`

#### Language & Runtime

**Language**: TypeScript  
**Version**: 4.9.5  
**Runtime**: Node.js 20+ LTS  
**Build Tool**: React Scripts 5.0.1

#### Dependencies

**Main Dependencies**:
- React 18.2.0 (UI library)
- Material-UI (MUI) 5.17.1 (component library)
- React Router DOM 6.30.1 (routing)
- TanStack React Query 5.80.7 (data fetching/caching)
- Axios 1.9.0 (HTTP client)
- TypeScript 4.9.5 (type checking)
- ECharts 5.6.0 & Recharts 2.15.3 (charting)
- Cytoscape 3.27.0 (graph visualization for network topology)
- Framer Motion 12.17.3 (animations)
- Tailwind CSS utilities (via inline styles and MUI)
- React Hook Form 7.57.0 (form management)
- xterm.js 5.5.0 (terminal emulation)

**Development Dependencies**:
- Prettier 3.1.0 (code formatting)
- HTTP Proxy Middleware (dev server proxy)

#### Build & Installation

```bash
cd vulnerability-manager-frontend
npm install
npm run build    # Production build
npm start        # Development server (port 3000)
npm run format   # Code formatting with Prettier
```

#### Docker

**Dockerfile**: `vulnerability-manager-frontend/Dockerfile`  
**Base Image**: node:18-alpine (builder) + nginx:1.25-alpine (runtime)  
**Build Process**: Multi-stage build with npm ci, npm run build  
**Runtime**: Nginx serving static files on port 80/443

#### Testing

**Framework**: React Scripts (Jest-based)  
**Test Command**: `npm test`  
**Configuration**: Jest (built-in via react-scripts)

#### Entry Point

**Main Components**:
- `src/index.tsx` - Application entry point
- `src/App.tsx` - Root component
- `public/index.html` - HTML template

#### Configuration

**TypeScript**: `tsconfig.json` (ES5 target, React JSX)  
**Environment**: `.env.example` contains template  
**API Proxy**: Default proxy to `http://localhost:8080`

---

### Packer VM Builder

**Configuration File**: `packer/debian13-sentinelcore.pkr.hcl`

#### Specification & Tools

**Type**: HashiCorp Packer (Infrastructure as Code)  
**Format**: HCL2  
**Required Tools**:
- Packer (latest)
- VirtualBox or QEMU/KVM
- Debian 13 ISO

#### Build Targets

- **VirtualBox**: OVA format (`.ova`)
- **QEMU/KVM**: QCOW2 format (`.qcow2`)
- Parallel build support available

#### Build Configuration

```bash
cd packer
packer init debian13-sentinelcore.pkr.hcl
packer validate debian13-sentinelcore.pkr.hcl
packer build debian13-sentinelcore.pkr.hcl
```

#### Build Variables

**Customizable**:
- `version` (default: 1.0.0)
- `memory` (default: 8192 MB)
- `cpus` (default: 4)
- `disk_size` (default: 50GB)

#### VM Specifications

**Default Resources**:
- CPU: 4 cores
- RAM: 8 GB
- Disk: 50 GB (thin provisioned)

**Installed Components**:
- Debian 13 (Trixie)
- PostgreSQL 15
- Node.js 20 LTS
- Rust (stable)
- Nginx
- SentinelCore (latest from main)

**Exposed Ports**:
- 22: SSH
- 80: HTTP
- 443: HTTPS
- 8080: API (internal)

#### Provisioning

**Scripts**: `packer/scripts/`
- `provision.sh` - Main installation script
- `cleanup.sh` - Image cleanup
- `first-boot.sh` - Initial configuration

---

## Build & Deployment Scripts

**Location**: `scripts/` and `scripts/deployment/`

### Installation Scripts

- `quick-install.sh` - One-liner installation for Debian 12+
- `setup.sh` - Manual installation setup
- `start.sh` - Service startup
- `migrations.sh` - Database migration runner

### Deployment Scripts

- `vm-setup-debian13.sh` - Full VM setup
- `build-deb.sh` - Debian package builder
- `regenerate-sqlx-cache.sh` - SQLx metadata generation
- `compile-offline.sh` - Offline compilation

## Default Credentials & Configuration

**Web Interface**:
- Email: `admin@sentinelcore.local`
- Password: `admin` (⚠️ Change immediately)

**SSH Access** (VM):
- User: `microcyber`
- Password: `microcyber` (⚠️ Change immediately)

**Environment Setup**: Copy `.env.production.example` to `.env` and configure before deployment

## Architecture Overview

- **Frontend**: React 18 → Nginx (containerized)
- **Backend**: Axum 0.6 → Rust (compiled binary)
- **Database**: PostgreSQL 15+ (standalone)
- **Network**: API on 8080, Nginx reverse proxy on 80/443
- **Auth**: JWT with httpOnly cookies, RBAC, 2FA support

## Key Technical Details

**Rust Dependencies**: Tokio async runtime, SQLx compile-time SQL checking, Axum with Tower middleware  
**React Dependencies**: React Query for state management, Material-UI for components, TypeScript for type safety  
**Database**: PostgreSQL JSONB, triggers, full-text search, audit logging  
**Security**: JWT + httpOnly, Argon2 password hashing, CORS, rate limiting, security headers  
**Testing**: React Scripts (Jest), Manual testing via npm test

## Documentation

- **User Guide**: `docs/USER_GUIDE.md`
- **API Reference**: `docs/API.md`
- **Security Guide**: `docs/SECURITY.md`
- **Deployment**: `docs/DEPLOYMENT.md`
- **Development**: `docs/development/DEVELOPMENT.md` & `ARCHITECTURE.md`
