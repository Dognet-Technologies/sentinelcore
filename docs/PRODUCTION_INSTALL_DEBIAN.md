# SentinelCore - Guida Installazione Production su Debian

Guida completa per l'installazione di SentinelCore in ambiente di produzione su Debian 12 (Bookworm) con deployment nativo (no Docker).

---

## Indice

1. [Requisiti di Sistema](#1-requisiti-di-sistema)
2. [Preparazione Sistema Debian](#2-preparazione-sistema-debian)
3. [Installazione e Configurazione PostgreSQL](#3-installazione-e-configurazione-postgresql)
4. [Installazione Dipendenze di Build](#4-installazione-dipendenze-di-build)
5. [Compilazione Backend (Rust)](#5-compilazione-backend-rust)
6. [Compilazione Frontend (React)](#6-compilazione-frontend-react)
7. [Configurazione Applicazione](#7-configurazione-applicazione)
8. [Setup Systemd Services](#8-setup-systemd-services)
9. [Configurazione Nginx Reverse Proxy](#9-configurazione-nginx-reverse-proxy)
10. [Configurazione Firewall](#10-configurazione-firewall)
11. [SSL/TLS con Let's Encrypt](#11-ssltls-con-lets-encrypt)
12. [Verifica Installazione](#12-verifica-installazione)
13. [Hardening di Sicurezza](#13-hardening-di-sicurezza)
14. [Backup e Manutenzione](#14-backup-e-manutenzione)
15. [Troubleshooting](#15-troubleshooting)

---

## 1. Requisiti di Sistema

### Hardware Minimo (Produzione)
- **CPU:** 4 core (8 thread consigliati)
- **RAM:** 8GB (16GB consigliati)
- **Storage:** 100GB SSD (RAID-1 consigliato)
- **Network:** 1Gbps

### Software
- **OS:** Debian 12 (Bookworm) - installazione minimal/server
- **PostgreSQL:** 15+
- **Rust:** 1.75+
- **Node.js:** 20 LTS
- **Nginx:** latest stable

### Porte Richieste
- `8080` - Backend API (interno)
- `3000` - Frontend development (interno)
- `80` - HTTP (redirect a HTTPS)
- `443` - HTTPS (pubblico)
- `5432` - PostgreSQL (solo localhost)

---

## 2. Preparazione Sistema Debian

### 2.1 Installazione Debian Base

Installare Debian 12 con le seguenti opzioni:
- Installazione **Server (no GUI)**
- Selezionare solo: **SSH server** + **standard system utilities**
- Configurare hostname: `sentinelcore.yourdomain.com`

### 2.2 Aggiornamento Sistema

```bash
# Login come root o usa sudo
sudo apt update
sudo apt upgrade -y
sudo apt install -y curl wget git build-essential pkg-config libssl-dev \
                     ufw fail2ban tmux htop ncdu
```

### 2.3 Creazione Utente Dedicato

```bash
# Crea utente sentinelcore
sudo useradd -m -s /bin/bash sentinelcore
sudo passwd sentinelcore

# Aggiungi a gruppo sudo (opzionale, per operazioni admin)
sudo usermod -aG sudo sentinelcore

# Switch all'utente
sudo su - sentinelcore
```

### 2.4 Configurazione Timezone e Locale

```bash
sudo timedatectl set-timezone Europe/Rome
sudo localectl set-locale LANG=en_US.UTF-8
```

---

## 3. Installazione e Configurazione PostgreSQL

### 3.1 Installazione PostgreSQL 15

```bash
# Installa PostgreSQL
sudo apt install -y postgresql-15 postgresql-contrib-15

# Verifica versione
psql --version  # Deve mostrare 15.x
```

### 3.2 Configurazione Sicurezza PostgreSQL

```bash
# Edita configurazione per sicurezza
sudo nano /etc/postgresql/15/main/postgresql.conf
```

Modifiche consigliate:
```conf
# Ascolta solo su localhost (sicurezza)
listen_addresses = 'localhost'

# Aumenta connessioni max per produzione
max_connections = 100

# Buffer memory (25% della RAM per server dedicato)
shared_buffers = 2GB

# Working memory
work_mem = 64MB
maintenance_work_mem = 512MB

# Logging per audit
logging_collector = on
log_directory = 'log'
log_filename = 'postgresql-%Y-%m-%d_%H%M%S.log'
log_statement = 'ddl'
log_min_duration_statement = 1000  # Log query > 1s
```

Salva e chiudi (`Ctrl+X`, `Y`, `Enter`).

### 3.3 Creazione Database e Utente

```bash
# Accedi come postgres
sudo -u postgres psql

# In PostgreSQL shell:
CREATE DATABASE sentinelcore_db;
CREATE USER sentinelcore_user WITH ENCRYPTED PASSWORD 'YourSecurePassword123!';
GRANT ALL PRIVILEGES ON DATABASE sentinelcore_db TO sentinelcore_user;

# Abilita estensioni necessarie
\c sentinelcore_db
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

# Esci
\q
```

### 3.4 Test Connessione

```bash
# Testa connessione
psql -h localhost -U sentinelcore_user -d sentinelcore_db

# Se chiede password, inserisci quella creata sopra
# Se funziona, esci con \q
```

### 3.5 Restart PostgreSQL

```bash
sudo systemctl restart postgresql
sudo systemctl enable postgresql
sudo systemctl status postgresql  # Verifica che sia active (running)
```

---

## 4. Installazione Dipendenze di Build

### 4.1 Installazione Rust

```bash
# Come utente sentinelcore
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Scegli opzione 1 (default installation)
# Poi carica l'environment
source $HOME/.cargo/env

# Verifica versione
rustc --version  # Deve essere >= 1.75
cargo --version
```

### 4.2 Installazione Node.js 20 LTS

```bash
# Installa Node Version Manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

# Carica nvm
source ~/.bashrc

# Installa Node.js 20 LTS
nvm install 20
nvm use 20
nvm alias default 20

# Verifica versioni
node --version  # Deve essere v20.x.x
npm --version
```

### 4.3 Installazione Nginx

```bash
sudo apt install -y nginx
sudo systemctl enable nginx
sudo systemctl start nginx
```

---

## 5. Compilazione Backend (Rust)

### 5.1 Clone Repository

```bash
# Come utente sentinelcore
cd /home/sentinelcore
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
```

### 5.2 Configurazione Environment Backend

```bash
# Crea file .env per il backend
cd /home/sentinelcore/sentinelcore/vulnerability-manager
nano .env
```

Contenuto `.env`:
```env
# Database Configuration
DATABASE_URL=postgresql://sentinelcore_user:YourSecurePassword123!@localhost:5432/sentinelcore_db

# Server Configuration
RUST_LOG=info
SERVER_HOST=127.0.0.1
SERVER_PORT=8080

# JWT Secret (genera una stringa random sicura)
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars

# CORS Configuration
CORS_ALLOWED_ORIGINS=https://sentinelcore.yourdomain.com

# Session Configuration
SESSION_TIMEOUT_HOURS=24
```

**IMPORTANTE:** Cambia `JWT_SECRET` con una stringa casuale sicura:
```bash
# Genera JWT secret sicuro
openssl rand -base64 48
```

### 5.3 Esecuzione Migrazioni Database

```bash
# Installa sqlx-cli
cargo install sqlx-cli --no-default-features --features postgres

# Esegui migrazioni
cd /home/sentinelcore/sentinelcore/vulnerability-manager
sqlx database create
sqlx migrate run
```

### 5.4 Build Backend (Release Mode)

```bash
cd /home/sentinelcore/sentinelcore/vulnerability-manager

# Build in modalità release (ottimizzato)
cargo build --release

# Questo processo richiede 10-20 minuti e molta RAM
# Il binario sarà in: target/release/vulnerability-manager
```

### 5.5 Verifica Binario

```bash
# Testa che il binario funzioni
./target/release/vulnerability-manager --version

# Test esecuzione (Ctrl+C per fermare)
./target/release/vulnerability-manager
```

---

## 6. Compilazione Frontend (React)

### 6.1 Installazione Dipendenze NPM

```bash
cd /home/sentinelcore/sentinelcore/vulnerability-manager-frontend

# Installa dipendenze
npm install
```

### 6.2 Configurazione Environment Frontend

```bash
nano .env.production
```

Contenuto `.env.production`:
```env
REACT_APP_API_URL=https://sentinelcore.yourdomain.com
REACT_APP_ENVIRONMENT=production
```

### 6.3 Build Production

```bash
# Build ottimizzata per produzione
npm run build

# Output sarà in ./build/
# Questa cartella contiene file statici pronti per essere serviti da Nginx
```

### 6.4 Copia Build in Directory Nginx

```bash
# Crea directory per frontend
sudo mkdir -p /var/www/sentinelcore

# Copia build
sudo cp -r build/* /var/www/sentinelcore/

# Imposta permessi
sudo chown -R www-data:www-data /var/www/sentinelcore
sudo chmod -R 755 /var/www/sentinelcore
```

---

## 7. Configurazione Applicazione

### 7.1 Creazione Directory Runtime

```bash
# Crea directory per logs e dati
sudo mkdir -p /var/log/sentinelcore
sudo mkdir -p /var/lib/sentinelcore

# Imposta ownership
sudo chown sentinelcore:sentinelcore /var/log/sentinelcore
sudo chown sentinelcore:sentinelcore /var/lib/sentinelcore
```

### 7.2 Copia Binario in Posizione Sistema

```bash
# Copia binario backend
sudo cp /home/sentinelcore/sentinelcore/vulnerability-manager/target/release/vulnerability-manager \
        /usr/local/bin/sentinelcore-backend

# Rendi eseguibile
sudo chmod +x /usr/local/bin/sentinelcore-backend

# Verifica
sentinelcore-backend --version
```

### 7.3 Creazione File Configurazione

```bash
# Crea directory config
sudo mkdir -p /etc/sentinelcore

# Copia config
sudo cp /home/sentinelcore/sentinelcore/vulnerability-manager/.env \
        /etc/sentinelcore/backend.env

# Proteggi file config (contiene password!)
sudo chmod 600 /etc/sentinelcore/backend.env
sudo chown sentinelcore:sentinelcore /etc/sentinelcore/backend.env
```

---

## 8. Setup Systemd Services

### 8.1 Servizio Backend

```bash
sudo nano /etc/systemd/system/sentinelcore-backend.service
```

Contenuto:
```ini
[Unit]
Description=SentinelCore Backend API
After=network.target postgresql.service
Requires=postgresql.service

[Service]
Type=simple
User=sentinelcore
Group=sentinelcore
WorkingDirectory=/var/lib/sentinelcore
EnvironmentFile=/etc/sentinelcore/backend.env
ExecStart=/usr/local/bin/sentinelcore-backend
Restart=always
RestartSec=10
StandardOutput=append:/var/log/sentinelcore/backend.log
StandardError=append:/var/log/sentinelcore/backend-error.log

# Security hardening
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/var/lib/sentinelcore /var/log/sentinelcore

# Resource limits
LimitNOFILE=65535
MemoryMax=4G
CPUQuota=200%

[Install]
WantedBy=multi-user.target
```

### 8.2 Avvio Servizi

```bash
# Reload systemd
sudo systemctl daemon-reload

# Abilita e avvia backend
sudo systemctl enable sentinelcore-backend
sudo systemctl start sentinelcore-backend

# Verifica status
sudo systemctl status sentinelcore-backend

# Verifica logs
sudo journalctl -u sentinelcore-backend -f
```

---

## 9. Configurazione Nginx Reverse Proxy

### 9.1 Configurazione Nginx

```bash
sudo nano /etc/nginx/sites-available/sentinelcore
```

Contenuto:
```nginx
# Upstream backend API
upstream sentinelcore_backend {
    server 127.0.0.1:8080 max_fails=3 fail_timeout=30s;
    keepalive 32;
}

# HTTP -> HTTPS redirect
server {
    listen 80;
    listen [::]:80;
    server_name sentinelcore.yourdomain.com;

    # Let's Encrypt challenge
    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    # Redirect everything else to HTTPS
    location / {
        return 301 https://$server_name$request_uri;
    }
}

# HTTPS Server
server {
    listen 443 ssl http2;
    listen [::]:443 ssl http2;
    server_name sentinelcore.yourdomain.com;

    # SSL Configuration (certificates will be added by certbot)
    ssl_certificate /etc/letsencrypt/live/sentinelcore.yourdomain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/sentinelcore.yourdomain.com/privkey.pem;

    # SSL Security
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;

    # Security Headers
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    # Root directory for frontend
    root /var/www/sentinelcore;
    index index.html;

    # Client max body size (per upload file)
    client_max_body_size 100M;

    # API Proxy
    location /api/ {
        proxy_pass http://sentinelcore_backend;
        proxy_http_version 1.1;

        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Connection "";

        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
    }

    # Frontend SPA - React Router
    location / {
        try_files $uri $uri/ /index.html;

        # Cache static assets
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }

    # Logs
    access_log /var/log/nginx/sentinelcore-access.log;
    error_log /var/log/nginx/sentinelcore-error.log warn;
}
```

### 9.2 Attivazione Configurazione

```bash
# Abilita sito
sudo ln -s /etc/nginx/sites-available/sentinelcore /etc/nginx/sites-enabled/

# Rimuovi default site (opzionale)
sudo rm /etc/nginx/sites-enabled/default

# Test configurazione
sudo nginx -t

# Se OK, reload nginx
sudo systemctl reload nginx
```

---

## 10. Configurazione Firewall

### 10.1 Setup UFW (Uncomplicated Firewall)

```bash
# Reset UFW (se già configurato)
sudo ufw --force reset

# Default policies
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (IMPORTANTE: fai questo PRIMA di abilitare UFW!)
sudo ufw allow 22/tcp comment 'SSH'

# Allow HTTP/HTTPS
sudo ufw allow 80/tcp comment 'HTTP'
sudo ufw allow 443/tcp comment 'HTTPS'

# Abilita UFW
sudo ufw enable

# Verifica status
sudo ufw status verbose
```

### 10.2 Fail2Ban per Protezione Brute-Force

```bash
# Configura fail2ban per nginx
sudo nano /etc/fail2ban/jail.local
```

Contenuto:
```ini
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 5

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/sentinelcore-error.log

[nginx-noscript]
enabled = true
port = http,https
logpath = /var/log/nginx/sentinelcore-access.log

[sshd]
enabled = true
port = 22
logpath = /var/log/auth.log
maxretry = 3
```

```bash
# Restart fail2ban
sudo systemctl restart fail2ban
sudo systemctl enable fail2ban
```

---

## 11. SSL/TLS con Let's Encrypt

### 11.1 Installazione Certbot

```bash
sudo apt install -y certbot python3-certbot-nginx
```

### 11.2 Ottenimento Certificato

**IMPORTANTE:** Prima di eseguire questo comando:
1. Assicurati che il DNS punti correttamente al server
2. Porta 80 deve essere aperta
3. Nginx deve essere in esecuzione

```bash
# Ottieni certificato SSL
sudo certbot --nginx -d sentinelcore.yourdomain.com

# Durante il processo:
# - Inserisci email per notifiche
# - Accetta Terms of Service
# - Scegli "2: Redirect" per forzare HTTPS
```

### 11.3 Test Rinnovo Automatico

```bash
# Certbot installa automaticamente un cron job per il rinnovo
# Test dry-run:
sudo certbot renew --dry-run

# Se test OK, il rinnovo automatico è configurato
```

### 11.4 Verifica SSL Configuration

Vai su: https://www.ssllabs.com/ssltest/
- Inserisci: `sentinelcore.yourdomain.com`
- Dovresti ottenere rating A/A+

---

## 12. Verifica Installazione

### 12.1 Health Checks

```bash
# 1. Verifica PostgreSQL
sudo systemctl status postgresql
sudo -u postgres psql -l | grep sentinelcore_db

# 2. Verifica Backend
sudo systemctl status sentinelcore-backend
curl -I http://localhost:8080/api/health

# 3. Verifica Nginx
sudo systemctl status nginx
sudo nginx -t

# 4. Verifica SSL
curl -I https://sentinelcore.yourdomain.com
```

### 12.2 Test Accesso Web

1. Apri browser: `https://sentinelcore.yourdomain.com`
2. Dovresti vedere la pagina di login SentinelCore
3. Login predefinito (**CAMBIARE SUBITO**):
   - Username: `admin`
   - Password: `admin123`

### 12.3 Verifica Logs

```bash
# Backend logs
sudo journalctl -u sentinelcore-backend -f

# Nginx access logs
sudo tail -f /var/log/nginx/sentinelcore-access.log

# Nginx error logs
sudo tail -f /var/log/nginx/sentinelcore-error.log

# PostgreSQL logs
sudo tail -f /var/log/postgresql/postgresql-15-main.log
```

---

## 13. Hardening di Sicurezza

### 13.1 Cambio Password Utente Admin

```bash
# Accedi all'applicazione web
# Vai su: Settings -> Users -> admin
# Cambia password con una sicura (min 16 caratteri, mix di caratteri)
```

### 13.2 Configurazione 2FA per Admin

```bash
# Nell'interfaccia web:
# Profile -> Security -> Enable Two-Factor Authentication
# Scansiona QR code con Google Authenticator / Authy
```

### 13.3 Disabilita PostgreSQL Remote Access

```bash
sudo nano /etc/postgresql/15/main/pg_hba.conf
```

Verifica che ci sia solo:
```
local   all             all                                     peer
host    all             all             127.0.0.1/32            scram-sha-256
host    all             all             ::1/128                 scram-sha-256
```

### 13.4 Limita Accesso SSH

```bash
sudo nano /etc/ssh/sshd_config
```

Modifiche consigliate:
```conf
PermitRootLogin no
PasswordAuthentication no  # Usa solo SSH keys
PubkeyAuthentication yes
MaxAuthTries 3
```

```bash
sudo systemctl restart sshd
```

### 13.5 Configurazione Automatic Security Updates

```bash
sudo apt install -y unattended-upgrades
sudo dpkg-reconfigure -plow unattended-upgrades
```

---

## 14. Backup e Manutenzione

### 14.1 Script Backup Database

```bash
sudo nano /usr/local/bin/sentinelcore-backup.sh
```

Contenuto:
```bash
#!/bin/bash
BACKUP_DIR="/var/backups/sentinelcore"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="sentinelcore_db"
DB_USER="sentinelcore_user"

mkdir -p $BACKUP_DIR

# Backup database
pg_dump -U $DB_USER -h localhost $DB_NAME | gzip > $BACKUP_DIR/db_backup_$DATE.sql.gz

# Mantieni solo backup ultimi 7 giorni
find $BACKUP_DIR -name "db_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completato: $BACKUP_DIR/db_backup_$DATE.sql.gz"
```

```bash
# Rendi eseguibile
sudo chmod +x /usr/local/bin/sentinelcore-backup.sh

# Test backup
sudo -u sentinelcore /usr/local/bin/sentinelcore-backup.sh
```

### 14.2 Cron Job Backup Automatico

```bash
sudo crontab -e
```

Aggiungi:
```cron
# Backup database ogni giorno alle 2 AM
0 2 * * * /usr/local/bin/sentinelcore-backup.sh >> /var/log/sentinelcore/backup.log 2>&1
```

### 14.3 Log Rotation

```bash
sudo nano /etc/logrotate.d/sentinelcore
```

Contenuto:
```
/var/log/sentinelcore/*.log {
    daily
    rotate 14
    compress
    delaycompress
    notifempty
    missingok
    sharedscripts
    postrotate
        systemctl reload sentinelcore-backend > /dev/null 2>&1 || true
    endscript
}
```

### 14.4 Monitoring Disk Usage

```bash
# Setup alert per disco pieno
sudo nano /usr/local/bin/check-disk-space.sh
```

Contenuto:
```bash
#!/bin/bash
THRESHOLD=85
USAGE=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')

if [ $USAGE -gt $THRESHOLD ]; then
    echo "ALERT: Disk usage is ${USAGE}% on $(hostname)" | \
        mail -s "Disk Space Alert - SentinelCore" admin@yourdomain.com
fi
```

---

## 15. Troubleshooting

### 15.1 Backend Non Si Avvia

```bash
# Controlla logs dettagliati
sudo journalctl -u sentinelcore-backend -n 100 --no-pager

# Problemi comuni:
# 1. Database non raggiungibile
sudo -u sentinelcore psql -h localhost -U sentinelcore_user -d sentinelcore_db

# 2. Porta 8080 già in uso
sudo lsof -i :8080

# 3. Permessi file configurazione
ls -la /etc/sentinelcore/backend.env
```

### 15.2 Nginx 502 Bad Gateway

```bash
# Verifica che backend sia running
sudo systemctl status sentinelcore-backend

# Test connessione diretta
curl http://localhost:8080/api/health

# Controlla logs nginx
sudo tail -f /var/log/nginx/sentinelcore-error.log
```

### 15.3 Database Connection Failed

```bash
# Verifica PostgreSQL
sudo systemctl status postgresql

# Test connessione manuale
psql -h localhost -U sentinelcore_user -d sentinelcore_db

# Controlla pg_hba.conf
sudo cat /etc/postgresql/15/main/pg_hba.conf | grep -v "^#"

# Restart PostgreSQL
sudo systemctl restart postgresql
```

### 15.4 High Memory Usage

```bash
# Controlla utilizzo memoria
free -h
htop

# Adjust systemd memory limit
sudo nano /etc/systemd/system/sentinelcore-backend.service
# Cambia MemoryMax= in base alle risorse

sudo systemctl daemon-reload
sudo systemctl restart sentinelcore-backend
```

### 15.5 SSL Certificate Issues

```bash
# Rinnovo manuale certificato
sudo certbot renew --force-renewal

# Test configurazione SSL
sudo nginx -t

# Controlla scadenza certificati
sudo certbot certificates
```

---

## Prossimi Passi

Dopo l'installazione:

1. **Configurazione Scanner Integration**
   - Configura importazione da Nessus/OpenVAS/Qualys
   - Vedi: `docs/SCANNER_INTEGRATION.md`

2. **Setup Team e Utenti**
   - Crea team di sicurezza
   - Aggiungi utenti
   - Configura ruoli (Admin, Team Leader, User)

3. **Notification Channels**
   - Configura Slack/Email/Teams per notifiche
   - Setup regole di notifica automatiche

4. **JIRA Integration** (opzionale)
   - Collega JIRA per ticketing automatico
   - Vedi: `docs/USER_GUIDE.md`

5. **Network Discovery**
   - Configura range di rete da scansionare
   - Setup scansioni automatiche nmap

---

## Supporto

- **Documentazione:** `/docs/`
- **Issues:** https://github.com/Dognet-Technologies/sentinelcore/issues
- **Email:** support@dognet.tech

---

**Versione Documento:** 1.0
**Ultima Modifica:** 2025-01-25
**Testato su:** Debian 12.4 (Bookworm)
