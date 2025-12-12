# SentinelCore - Vulnerability Management System

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Rust](https://img.shields.io/badge/Rust-1.75+-orange.svg)](https://www.rust-lang.org/)
[![React](https://img.shields.io/badge/React-18+-blue.svg)](https://reactjs.org/)

SentinelCore is a comprehensive vulnerability management platform designed for security teams to efficiently track, manage, and remediate security vulnerabilities across their infrastructure.

## ✨ Key Features

### Core Security
- 🔒 **Secure by Design** - JWT authentication with httpOnly cookies, RBAC, CSRF protection, security headers
- 🎯 **Vulnerability Management** - Track, prioritize, and remediate security vulnerabilities
- 🧮 **Intelligent Risk Scoring** - Advanced formula: (CVSS×0.30) + (EPSS×0.25) + (Business×0.25) + (Exposure×0.15) + (Exploit×0.05)
- ⏰ **SLA Automation** - Automatic deadline calculation and breach alerting (Critical: 1d, High: 7d, Medium: 30d)
- 🚨 **Priority Overrides** - Auto-escalate zero-days, ransomware-targeted, and actively exploited CVEs

### Team & Collaboration
- 👥 **Team Management** - Multi-team support with role-based access control
- 💬 **Comments System** - Built-in collaboration with @mentions, threading, and attachments
- 📋 **Remediation Plans** - Structured workflows with step tracking and assignment
- 📊 **Workload Dashboard** - Team capacity tracking and task distribution

### Integrations & Automation
- 🔌 **Scanner Integration** - Import from Qualys, Nessus, Burp Suite, OpenVAS, Nexpose (5/13 scanners)
- 🎫 **JIRA Auto-Ticketing** - Bi-directional sync with configurable rules and priority mapping
- 🔔 **Smart Notifications** - Rule-based routing to Email, Slack, Telegram with throttling and quiet hours
- 📈 **Executive Reporting** - Management reports with KPIs, trends, and compliance mapping

### Network & Discovery
- 🌐 **Network Scanning** - Built-in network discovery and vulnerability scanning
- 🔄 **Automated Remediation** - Workflow automation for common security fixes
- 🗺️ **Device Management** - Edit devices, bulk operations, multi-select, assignment tracking

### Intelligence
- 📊 **CVSS & EPSS Scoring** - Industry-standard vulnerability metrics
- 🎯 **Exploit Intelligence** - Metasploit, ExploitDB, CISA KEV catalog integration (roadmap)
- 🏢 **Business Impact** - Asset criticality, sensitive data, revenue impact scoring
- 🌍 **Asset Exposure** - Network position analysis (Internet-facing, DMZ, Internal, Isolated)

## 🚀 Quick Start

### Prerequisites

- Debian 12 or Ubuntu 22.04+ (recommended)
- OR: PostgreSQL 15+, Rust 1.75+, Node.js 20+

### Option 1: One-Liner Install (Fastest! ⚡)

**Install SentinelCore with a single command:**

\`\`\`bash
curl -sSL https://raw.githubusercontent.com/Dognet-Technologies/sentinelcore/main/scripts/quick-install.sh | sudo bash
\`\`\`

**What it does:**
- ✅ Installs all dependencies (PostgreSQL, Nginx, Rust, Node.js)
- ✅ Clones repository
- ✅ Compiles backend + frontend
- ✅ Sets up database with migrations
- ✅ Configures systemd service
- ✅ Ready in ~20 minutes!

**After installation:**
\`\`\`bash
# Access web UI
http://<your-server-ip>

# Default credentials
Email: admin@sentinelcore.local
Password: admin

# Service management
sudo systemctl status sentinelcore
sudo systemctl restart sentinelcore
\`\`\`

### Option 2: Manual VM Setup

**Step-by-step manual installation:**

\`\`\`bash
# 1. Clone repository
cd /opt
sudo mkdir sentinelcore
sudo chown $USER:$USER sentinelcore
git clone https://github.com/Dognet-Technologies/sentinelcore.git sentinelcore

# 2. Run automated setup
cd sentinelcore
sudo ./scripts/deployment/vm-setup-debian13.sh
\`\`\`

See [docs/VM_MANUAL_QUICKSTART.md](docs/VM_MANUAL_QUICKSTART.md) for detailed guide.

### Option 3: Debian Package (.deb)

\`\`\`bash
# Build .deb package
cd sentinelcore
./scripts/deployment/build-deb.sh

# Install package
sudo dpkg -i sentinelcore_1.0.0_amd64.deb
\`\`\`

### Default Credentials

- **Email:** \`admin@sentinelcore.local\`
- **Password:** \`admin\`

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
