# SentinelCore - Vulnerability Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)](https://www.rust-lang.org/)
[![React](https://img.shields.io/badge/React-18+-blue.svg)](https://reactjs.org/)

SentinelCore is a comprehensive vulnerability management platform designed for security teams to efficiently track, manage, and remediate security vulnerabilities across their infrastructure.

## ✨ Key Features

- 🔒 **Secure by Design** - JWT authentication with httpOnly cookies, RBAC, security headers
- 🎯 **Vulnerability Management** - Track, prioritize, and remediate security vulnerabilities
- 👥 **Team Collaboration** - Multi-team support with role-based access control
- 📊 **Risk Analysis** - CVSS scoring, EPSS integration, risk prioritization
- 🔌 **Scanner Integration** - Import from Qualys, Nessus, Burp Suite, OpenVAS, Nexpose
- 📈 **Executive Reporting** - Management reports with KPIs and metrics
- 🌐 **Network Scanning** - Built-in network discovery and vulnerability scanning
- 🔄 **Automated Remediation** - Workflow automation for common security fixes
- 📧 **Notifications** - Email, Slack, and webhook integrations
- 🐳 **Docker Ready** - Full containerized deployment with Docker Compose

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose (recommended)
- OR: PostgreSQL 14+, Rust 1.75+, Node.js 18+

### Option 1: Docker (Recommended)

\`\`\`bash
# Clone the repository
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore

# Copy environment configuration
cp .env.production.example .env

# Edit .env and set your secrets
nano .env

# Start with Docker Compose
docker-compose up -d

# Access the application
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080
\`\`\`

### Option 2: Manual Setup

See [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for detailed installation instructions.

### Default Credentials

- **Username:** \`admin\`
- **Password:** \`DogNET2024!\`

**⚠️ IMPORTANT:** Change the default password immediately after first login!

## 📚 Documentation

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Complete deployment instructions
- **[Security Setup](docs/SECURITY.md)** - Security configuration and best practices
- **[API Documentation](docs/API.md)** - REST API reference
- **[Scanner Integration](docs/SCANNER_INTEGRATION.md)** - Import from security scanners

### For Developers

- **[Development Guide](docs/development/DEVELOPMENT.md)** - Setup development environment
- **[Architecture](docs/development/ARCHITECTURE.md)** - System architecture overview

## 🏗️ Architecture

\`\`\`
┌─────────────────┐      ┌──────────────────┐
│  React Frontend │ ───▶ │   Axum Backend   │
│   (TypeScript)  │      │     (Rust)       │
└─────────────────┘      └──────────────────┘
                                  │
                         ┌────────┴────────┐
                         │   PostgreSQL    │
                         │    Database     │
                         └─────────────────┘
\`\`\`

- **Backend:** Rust with Axum 0.6 web framework
- **Frontend:** React 18 with TypeScript
- **Database:** PostgreSQL 14+ with JSONB support
- **Authentication:** JWT with httpOnly cookies
- **Security:** RBAC, CORS, rate limiting, security headers

## 🔌 Scanner Integration

SentinelCore can import vulnerability data from major security scanners:

- **Qualys** - XML report import
- **Nessus** - .nessus XML format
- **Burp Suite** - JSON issue export
- **OpenVAS/GVM** - XML reports
- **Nexpose/InsightVM** - XML format

Upload scan results via API or web interface for centralized vulnerability management.

## 🛡️ Security Features

- ✅ JWT authentication with httpOnly cookies (XSS protection)
- ✅ Role-Based Access Control (Admin, Team Leader, User)
- ✅ Security headers (HSTS, CSP, X-Frame-Options, etc.)
- ✅ CORS whitelist configuration
- ✅ Rate limiting and brute force protection
- ✅ CSRF protection
- ✅ Password policy enforcement
- ✅ Two-Factor Authentication (2FA)
- ✅ Session management and revocation
- ✅ Audit logging

## 📊 Roles & Permissions

### Admin
- Full system access
- User and team management
- System configuration
- Security settings

### Team Leader
- Manage team members
- Assign vulnerabilities to team
- View team metrics
- Create reports

### User
- View assigned vulnerabilities
- Update vulnerability status
- Comment on vulnerabilities
- Export data

## 🔧 Development

\`\`\`bash
# Backend (Rust)
cd vulnerability-manager
cargo build
cargo run

# Frontend (React)
cd vulnerability-manager-frontend
npm install
npm start

# Run tests
cargo test
npm test
\`\`\`

## 📝 Scripts

Useful scripts are available in the \`scripts/\` directory:

- \`scripts/setup.sh\` - Initial setup and dependency installation
- \`scripts/start.sh\` - Start all services
- \`scripts/migrations.sh\` - Run database migrations

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built with [Axum](https://github.com/tokio-rs/axum) and [React](https://reactjs.org/)
- Created by [Dognet Technologies](https://github.com/Dognet-Technologies)

## 📞 Support

- 🐛 Issues: [GitHub Issues](https://github.com/Dognet-Technologies/sentinelcore/issues)

---

**Made with ❤️ by Dognet Technologies**
