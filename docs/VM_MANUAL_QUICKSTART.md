# VM SentinelCore - Guida Installazione Manuale Rapida

**Target:** Debian 12 (Bookworm) headless
**Utente:** `microcyber` (default MicroCyber suite)
**Tempo:** ~30 minuti

---

## Parte 1: Installazione Base Debian 12 (10 min)

### 1. Crea VM con VirtualBox/VMware

**Specifiche minime:**
- CPU: 4 cores
- RAM: 8 GB
- Disco: 50 GB (dinamico)
- Network: Bridged Adapter (per accesso rete)

### 2. Installa Debian 12

Scarica ISO: https://www.debian.org/distrib/

**Durante installazione:**
```
Hostname: sentinelcore-server
Domain: (lascia vuoto)
Root password: (scegli forte)
New user: microcyber
Password: microcyber (cambiare dopo!)
Partitioning: Guided - use entire disk
Software selection:
  [x] SSH server
  [x] standard system utilities
  [ ] NESSUN desktop environment!
```

### 3. Primo Boot

Accedi come `microcyber` (via SSH o console):

```bash
ssh microcyber@<vm-ip>
```

Aggiorna sistema:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget build-essential
```

---

## Parte 2: Installazione Automatica SentinelCore (15 min)

### 1. Clona Repository

```bash
cd /opt
sudo mkdir sentinelcore
sudo chown microcyber:microcyber sentinelcore
git clone https://github.com/Dognet-Technologies/sentinelcore.git sentinelcore
cd sentinelcore
```

### 2. Esegui Script Setup Automatico

```bash
sudo chmod +x scripts/deployment/vm-setup-debian13.sh
sudo ./scripts/deployment/vm-setup-debian13.sh
```

**Lo script installa automaticamente:**
- ✅ PostgreSQL 15
- ✅ Nginx (reverse proxy)
- ✅ Node.js 20 LTS
- ✅ Rust toolchain (latest stable)
- ✅ Dipendenze sistema (libpq-dev, libssl-dev, pkg-config)
- ✅ SentinelCore backend (compila da sorgente)
- ✅ SentinelCore frontend (build production)
- ✅ Database setup (crea DB + migrazioni)
- ✅ Servizio systemd
- ✅ Configurazione Nginx

**Tempo stimato:** 15-20 minuti (dipende da velocità rete + CPU)

### 3. Verifica Installazione

```bash
# Verifica servizio attivo
sudo systemctl status sentinelcore

# Verifica database
sudo -u postgres psql -l | grep sentinelcore

# Verifica Nginx
curl http://localhost

# Verifica log
sudo journalctl -u sentinelcore -n 50
```

**Output atteso:**
```
● sentinelcore.service - SentinelCore Vulnerability Manager
   Active: active (running)
```

---

## Parte 3: Configurazione Post-Installazione (5 min)

### 1. Cambia Password Default

```bash
# Password sistema
passwd

# Password admin web (cambiare al primo login)
# Vai su http://<vm-ip>
# Login: admin@sentinelcore.local
# Password iniziale: admin
# Ti verrà richiesto di cambiarla
```

### 2. Configura IP Statico (Opzionale)

**Se vuoi IP fisso invece di DHCP:**

```bash
sudo nano /etc/network/interfaces
```

Aggiungi:
```
auto enp0s3
iface enp0s3 inet static
    address 192.168.1.100
    netmask 255.255.255.0
    gateway 192.168.1.1
    dns-nameservers 8.8.8.8 8.8.4.4
```

Riavvia networking:
```bash
sudo systemctl restart networking
```

### 3. Configura Firewall (Opzionale ma Consigliato)

```bash
sudo apt install -y ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS (se configuri SSL)
sudo ufw enable
```

### 4. Configura SSL/TLS (Produzione)

Per usare HTTPS in produzione:

```bash
# Installa certbot
sudo apt install -y certbot python3-certbot-nginx

# Ottieni certificato (serve dominio pubblico)
sudo certbot --nginx -d sentinelcore.tuodominio.com

# Auto-renewal configurato automaticamente
```

---

## Parte 4: Primo Accesso e Test

### 1. Accedi all'Applicazione

Apri browser:
```
http://<vm-ip>
```

**Credenziali default:**
- Email: `admin@sentinelcore.local`
- Password: `admin`

⚠️ **Cambia immediatamente la password!**

### 2. Verifica Funzionalità

Dashboard dovrebbe mostrare:
- ✅ 0 vulnerabilità (database vuoto)
- ✅ Menu: Dashboard, Assets, Vulnerabilities, Network, Reports, Settings
- ✅ Nessun errore JavaScript in console browser

### 3. Test Import Scanner

Prova a importare un file di test:

```bash
# Crea vulnerability di test
curl -X POST http://localhost/api/vulnerabilities \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "title": "Test Vulnerability",
    "description": "Test import",
    "severity": "high",
    "cvss_score": 7.5,
    "ip_address": "192.168.1.100"
  }'
```

---

## Aggiornamenti Futuri

### Aggiornare SentinelCore

Quando disponibile nuova versione:

```bash
cd /opt/sentinelcore
sudo ./scripts/deployment/update_tools.sh
```

**Lo script fa automaticamente:**
1. ✅ Backup database PostgreSQL
2. ✅ Pull aggiornamenti da GitHub
3. ✅ Applica nuove migrazioni DB
4. ✅ Ricompila backend + frontend
5. ✅ Riavvia servizio

**Sicurezza dati:** I tuoi dati sono al sicuro!
- Database separato da codice applicativo
- Migrazioni incrementali (non cancellano dati)
- Backup automatico prima di ogni update

---

## Troubleshooting

### Servizio Non Parte

```bash
# Verifica log errori
sudo journalctl -u sentinelcore -xe

# Verifica configurazione
cat /etc/systemd/system/sentinelcore.service

# Riavvia manualmente
sudo systemctl restart sentinelcore
```

### Errori Database

```bash
# Verifica PostgreSQL attivo
sudo systemctl status postgresql

# Connetti al database
sudo -u postgres psql sentinelcore_db

# Verifica migrazioni applicate
SELECT * FROM _sqlx_migrations ORDER BY installed_on DESC;
```

### Errori Compilazione

```bash
cd /opt/sentinelcore/vulnerability-manager

# Rigenera cache SQLx
../scripts/deployment/regenerate-sqlx-cache.sh

# Compila con log dettagliati
SQLX_OFFLINE=true cargo build --release --verbose 2>&1 | tee build.log
```

### Port 80 già in uso

```bash
# Trova processo che usa porta 80
sudo lsof -i :80

# Ferma Apache (se installato per errore)
sudo systemctl stop apache2
sudo systemctl disable apache2

# Riavvia Nginx
sudo systemctl restart nginx
```

---

## Backup e Restore

### Backup Completo

```bash
# Backup database
sudo -u postgres pg_dump sentinelcore_db > ~/sentinelcore_backup_$(date +%Y%m%d).sql

# Backup configurazione
tar czf ~/sentinelcore_config_$(date +%Y%m%d).tar.gz \
  /opt/sentinelcore/.env \
  /etc/nginx/sites-available/sentinelcore \
  /etc/systemd/system/sentinelcore.service
```

### Restore Database

```bash
# Stop servizio
sudo systemctl stop sentinelcore

# Restore database
sudo -u postgres psql sentinelcore_db < ~/sentinelcore_backup_20251212.sql

# Riavvia servizio
sudo systemctl start sentinelcore
```

---

## Specifiche Tecniche

### Directory Structure

```
/opt/sentinelcore/              # Codice applicazione
  ├── vulnerability-manager/     # Backend Rust
  │   ├── src/                   # Codice sorgente
  │   ├── migrations/            # Migrazioni database
  │   └── target/release/        # Binary compilato
  ├── vulnerability-manager-frontend/  # Frontend React
  │   ├── src/                   # Codice sorgente
  │   └── build/                 # Build production
  ├── scripts/                   # Script utility
  └── docs/                      # Documentazione

/var/lib/sentinelcore/          # Dati applicazione
/var/log/sentinelcore/          # Log applicazione
/etc/systemd/system/sentinelcore.service  # Service file
/etc/nginx/sites-available/sentinelcore   # Nginx config
```

### Porte Utilizzate

- **80** (HTTP): Nginx → Frontend
- **8080** (interno): Backend API Rust
- **5432** (interno): PostgreSQL database

### Servizi

```bash
# SentinelCore
sudo systemctl status sentinelcore
sudo systemctl restart sentinelcore
sudo systemctl stop sentinelcore

# PostgreSQL
sudo systemctl status postgresql
sudo systemctl restart postgresql

# Nginx
sudo systemctl status nginx
sudo systemctl restart nginx
```

---

## Metriche Performance

**Dopo installazione completa:**
- Spazio disco utilizzato: ~5 GB
- RAM utilizzata: ~1.5 GB (backend + PostgreSQL + Nginx)
- Processo backend: ~200 MB RAM
- Database PostgreSQL: ~100 MB RAM (vuoto, cresce con dati)

---

## Export VM per Distribuzione

Una volta configurata la VM, puoi esportarla per distribuirla:

### VirtualBox

```bash
# Da host (non VM)
VBoxManage export sentinelcore-vm -o sentinelcore-v1.0.ova
```

### VMware

```
File → Export to OVF/OVA
```

### Compress per distribuzione

```bash
# Comprimi OVA
tar czf sentinelcore-v1.0.tar.gz sentinelcore-v1.0.ova

# Calcola checksum
sha256sum sentinelcore-v1.0.tar.gz > sentinelcore-v1.0.sha256
```

**Distribuisci:**
- `sentinelcore-v1.0.tar.gz` (~2-3 GB compressed)
- `sentinelcore-v1.0.sha256` (checksum verification)
- `VM_QUICKSTART.md` (guida utente finale)

---

## Supporto

**Documentazione:**
- Repository: https://github.com/Dognet-Technologies/sentinelcore
- Issues: https://github.com/Dognet-Technologies/sentinelcore/issues

**File Utili:**
- `docs/DEPLOYMENT.md` - Deployment dettagliato
- `docs/API.md` - API documentation
- `docs/USER_GUIDE.md` - Guida utente completa
- `docs/SECURITY.md` - Security best practices

---

**VM pronta per produzione!** 🎉
