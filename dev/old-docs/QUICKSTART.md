# 🚀 Sentinel Core - Quick Start Guide

## 📋 Prerequisiti

- ✅ PostgreSQL 14+ installato
- ✅ Rust 1.70+ installato (`cargo --version`)
- ✅ Node.js 18+ installato (`node --version`)
- ✅ npm installato (`npm --version`)

## 🔧 Setup Iniziale (Eseguire UNA VOLTA)

### 1. Avvia PostgreSQL

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql  # Avvio automatico
```

### 2. Crea Database e Utente

```bash
sudo -u postgres psql
```

Dentro PostgreSQL:

```sql
CREATE USER vlnman WITH PASSWORD 'DogNET';
CREATE DATABASE vulnerability_manager OWNER vlnman;
\c vulnerability_manager
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
\q
```

### 3. Esegui le Migrations

```bash
./run-migrations.sh
```

Questo creerà tutte le tabelle necessarie:
- ✅ users, teams, team_members
- ✅ vulnerabilities, assets, resolutions
- ✅ reports, plugins, notifications
- ✅ **network_devices, network_links** (NUOVO!)
- ✅ **network_scans, device_vulnerabilities** (NUOVO!)
- ✅ **remediation_tasks** (NUOVO!)

### 4. Configura Variabili d'Ambiente (Opzionale)

Modifica `vulnerability-manager/.env`:

```bash
nano vulnerability-manager/.env
```

Configura (opzionali):
- SMTP per email
- Telegram Bot Token per notifiche
- JWT Secret per produzione

---

## 🚀 Avvio Applicazione

### Metodo 1: Script Automatici (CONSIGLIATO)

**Terminal 1 - Backend:**
```bash
./start-backend.sh
```

**Terminal 2 - Frontend:**
```bash
./start-frontend.sh
```

### Metodo 2: Manuale

**Backend:**
```bash
cd vulnerability-manager
cargo run --release
```

**Frontend:**
```bash
cd vulnerability-manager-frontend
npm start
```

---

## 🌐 Accesso Applicazione

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080
- **API Health Check:** http://localhost:8080/api/health

### Credenziali di Default

Se hai eseguito `seed_data.sql`:

**Admin:**
- Username: `admin`
- Password: `Admin123!`

**Team Leader:**
- Username: `team_leader`
- Password: `TeamLead123!`

**User:**
- Username: `user`
- Password: `User123!`

---

## 🆕 Nuove Features Implementate

### 1️⃣ Export Report Multi-Formato

```bash
# API Endpoint
GET /api/reports/:id/export?format=pdf
GET /api/reports/:id/export?format=xml
GET /api/reports/:id/export?format=json
GET /api/reports/:id/export?format=csv
```

Formati supportati:
- **PDF** - Con grafici e statistiche
- **XML** - Strutturato con metadata
- **JSON** - Pretty-printed
- **CSV** - Tabella Excel-ready

### 2️⃣ Notifiche Multi-Canale

**Slack:**
```bash
# Configura webhook in team settings
POST /api/teams/:id
{
  "slack_webhook": "https://hooks.slack.com/services/..."
}
```

**Telegram:**
```bash
# Configura bot token in .env
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...

# Configura chat_id in team settings
POST /api/teams/:id
{
  "telegram_chat_id": "-1001234567890"
}
```

**Email:**
```bash
# Configura SMTP in .env
SMTP_SERVER=smtp.gmail.com
SMTP_USERNAME=your@email.com
SMTP_PASSWORD=your-app-password
```

### 3️⃣ Network Scan & Topology Visualization ⭐

**Accedi alla nuova feature:**

1. Apri frontend: http://localhost:3000
2. Naviga a "Network Scan" (aggiungi alla tua dashboard)
3. Click su "Start Scan"
4. Visualizza topologia grafica della rete
5. Click destro su device → Fix Vulnerabilities
6. Scegli: Auto Remediation, Script, o Terminal

**API Endpoints:**

```bash
# Avvia network scan
POST /api/network/scan
{
  "scan_name": "Production Network",
  "scan_type": "arp-scan",
  "target_range": "192.168.1.0/24",
  "include_port_scan": true,
  "include_os_detection": true
}

# Ottieni topologia
GET /api/network/topology

# Device details + vulnerabilità
GET /api/network/devices/:id/details

# Esegui remediation
POST /api/network/devices/:id/remediate
{
  "vulnerability_id": "...",
  "remediation_type": "auto",
  "script": "#!/bin/bash\n..."
}
```

**Componenti React:**

```typescript
import {
  NetworkTopologyView,
  DeviceContextMenu,
  RemediationPanel,
  TerminalEmulator
} from './components/network';

// In tua dashboard:
<NetworkTopologyView />
```

---

## 🛠️ Tool Esterni Necessari

Per network scanning completo:

```bash
# arp-scan (per discovery rete locale)
sudo apt install arp-scan

# nmap (per port scan e OS detection)
sudo apt install nmap

# traceroute (per topologia routing)
sudo apt install traceroute
```

---

## 🐛 Troubleshooting

### Backend non compila

```bash
# SQLx richiede database attivo, usa offline mode:
cd vulnerability-manager
cargo sqlx prepare
# oppure
export SQLX_OFFLINE=true
cargo build
```

### Database connection error

```bash
# Verifica PostgreSQL
sudo systemctl status postgresql

# Verifica connessione
psql postgresql://vlnman:DogNET@localhost/vulnerability_manager -c "SELECT 1;"
```

### Frontend dipendenze mancanti

```bash
cd vulnerability-manager-frontend
rm -rf node_modules package-lock.json
npm install
```

### Permission denied su network scan

```bash
# arp-scan e nmap richiedono permessi root
# Opzione 1: Esegui backend come root (NON consigliato in produzione)
sudo cargo run

# Opzione 2: Configura sudo senza password per specifici comandi
sudo visudo
# Aggiungi:
# www-data ALL=(ALL) NOPASSWD: /usr/bin/arp-scan, /usr/bin/nmap
```

---

## 📚 Documentazione Completa

- **Backend API:** http://localhost:8080/api/docs (se configurato Swagger)
- **Frontend Components:** `/vulnerability-manager-frontend/src/components/`
- **Database Schema:** `/vulnerability-manager/migrations/`

---

## 🔒 Sicurezza in Produzione

**IMPORTANTE:** Prima di andare in produzione:

1. ✅ Cambia JWT_SECRET in .env
2. ✅ Cambia password database
3. ✅ Configura HTTPS/TLS
4. ✅ Abilita rate limiting
5. ✅ Configura firewall
6. ✅ Usa variabili d'ambiente separate
7. ✅ Abilita audit logging
8. ✅ Configura backup automatici

---

## 📞 Supporto

Per problemi o domande:
- Controlla i log: `RUST_LOG=debug cargo run`
- Verifica le migrations: `psql $DATABASE_URL -c "\dt"`
- Controlla network: `netstat -tlnp | grep 8080`

---

**Buon testing! 🎉**
