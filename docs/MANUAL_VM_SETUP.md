# Setup Manuale VM SentinelCore

Guida per creare manualmente una VM Debian con SentinelCore installato e configurato.

## Prerequisiti

- VirtualBox, VMware o KVM/QEMU
- ISO Debian 12 (Bookworm)
- Minimo 2 CPU, 4GB RAM, 30GB disco

## Parte 1: Installazione Base Debian

### 1.1 Crea Nuova VM

**VirtualBox:**
```bash
- Nome: SentinelCore-Production
- Tipo: Linux
- Versione: Debian (64-bit)
- RAM: 8192 MB (8GB)
- Disco: 50 GB (dinamico)
- CPU: 4 core
```

### 1.2 Installa Debian 12

Durante l'installazione:
- ✅ **Hostname:** `sentinelcore-server`
- ✅ **Username:** `microcyber` (default per suite MicroCyber)
- ✅ **Password:** `microcyber` (cambiare dopo primo accesso!)
- ✅ **Software selection:**
  - [x] SSH server
  - [x] standard system utilities
  - [ ] **NO desktop environment** (headless)

### 1.3 Configurazione Post-Installazione

Dopo il primo boot, accedi via SSH o console:

```bash
ssh microcyber@<vm-ip>
```

Aggiorna il sistema:
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget
```

## Parte 2: Installazione SentinelCore

### 2.1 Clona Repository da GitHub

```bash
cd /opt
sudo mkdir -p sentinelcore
sudo chown microcyber:microcyber sentinelcore
git clone https://github.com/Dognet-Technologies/sentinelcore.git sentinelcore
cd sentinelcore
```

### 2.2 Esegui Script di Setup Automatico

```bash
sudo ./scripts/deployment/vm-setup-debian13.sh
```

Lo script installerà automaticamente:
- ✅ PostgreSQL 15
- ✅ Nginx (reverse proxy)
- ✅ Node.js 20 (per frontend)
- ✅ Rust (per backend)
- ✅ Dipendenze sistema
- ✅ SentinelCore (compilazione e configurazione)
- ✅ Servizi systemd

**Tempo stimato:** 20-30 minuti

### 2.3 Verifica Installazione

```bash
# Verifica servizio attivo
sudo systemctl status sentinelcore

# Verifica database
sudo -u postgres psql -l | grep sentinelcore

# Verifica web server
curl http://localhost
```

## Parte 3: Configurazione Iniziale

### 3.1 Cambia Password Default

```bash
# Password utente sistema
passwd

# Password admin web (dopo primo login)
# Login: admin@sentinelcore.local
# Password iniziale: admin
# Ti verrà chiesto di cambiarla al primo accesso
```

### 3.2 Configurazione Rete

**Assegnare IP statico (opzionale):**

```bash
sudo nano /etc/network/interfaces
```

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

### 3.3 Configurazione Firewall (Opzionale)

```bash
sudo apt install -y ufw
sudo ufw allow 22/tcp   # SSH
sudo ufw allow 80/tcp   # HTTP
sudo ufw allow 443/tcp  # HTTPS
sudo ufw enable
```

## Parte 4: Aggiornamenti

### 4.1 Aggiornare SentinelCore

Quando è disponibile una nuova versione:

```bash
cd /opt/sentinelcore
sudo ./scripts/deployment/update_tools.sh
```

Lo script:
1. ✅ Fa backup automatico del database
2. ✅ Scarica gli aggiornamenti da GitHub
3. ✅ Applica nuove migrazioni database
4. ✅ Ricompila l'applicazione
5. ✅ Riavvia il servizio

**I tuoi dati sono sicuri!** Il database PostgreSQL è separato dal codice applicativo.

### 4.2 Sicurezza dei Dati

**Perché i dati NON vengono persi durante gli aggiornamenti:**

✅ **Database separato:** PostgreSQL memorizza i dati in `/var/lib/postgresql`, completamente separato dal codice in `/opt/sentinelcore`

✅ **Migrazioni incrementali:** Le migrazioni SQLx aggiungono/modificano tabelle senza cancellare dati esistenti:
```sql
-- Esempio migrazione sicura
ALTER TABLE devices ADD COLUMN IF NOT EXISTS new_field TEXT;
-- Aggiunge colonna, dati esistenti intatti
```

✅ **Backup automatico:** Ogni aggiornamento crea un backup del database:
```bash
/var/backups/sentinelcore/sentinelcore_backup_YYYYMMDD_HHMMSS.sql
```

✅ **Rollback facile:** In caso di problemi:
```bash
sudo -u postgres psql sentinelcore_db < /var/backups/sentinelcore/backup.sql
```

### 4.3 Backup Manuale (Consigliato)

Prima di aggiornamenti importanti:

```bash
# Backup completo
sudo -u postgres pg_dump sentinelcore_db > ~/sentinelcore_backup.sql

# Backup compresso
sudo -u postgres pg_dump sentinelcore_db | gzip > ~/sentinelcore_backup.sql.gz

# Ripristino
sudo -u postgres psql sentinelcore_db < ~/sentinelcore_backup.sql
```

## Parte 5: Troubleshooting

### 5.1 Servizio Non Parte

```bash
# Log del servizio
sudo journalctl -u sentinelcore -n 50 --no-pager

# Log applicazione
sudo tail -f /var/log/sentinelcore/sentinelcore.log

# Riavvio manuale
sudo systemctl restart sentinelcore
```

### 5.2 Errori Database

```bash
# Verifica connessione
sudo -u postgres psql sentinelcore_db -c "SELECT version();"

# Riavvia PostgreSQL
sudo systemctl restart postgresql

# Controlla migrazioni applicate
sudo -u postgres psql sentinelcore_db -c "SELECT * FROM _sqlx_migrations ORDER BY installed_on DESC LIMIT 5;"
```

### 5.3 Problemi Compilazione

```bash
cd /opt/sentinelcore/vulnerability-manager

# Rigenera cache SQLx
../scripts/deployment/regenerate-sqlx-cache.sh

# Compila con log dettagliati
SQLX_OFFLINE=true cargo build --release --verbose
```

## Accesso Applicazione

### Web UI
```
http://<vm-ip>
```

**Credenziali default:**
- Email: `admin@sentinelcore.local`
- Password: `admin`

⚠️ **IMPORTANTE:** Cambia la password al primo accesso!

### API Endpoint
```
http://<vm-ip>/api/v1
```

Documentazione API:
```
http://<vm-ip>/api/docs
```

## Export/Import VM

### Export VM (per distribuzione)

**VirtualBox:**
```bash
VBoxManage export SentinelCore-Production -o sentinelcore-v1.0.ova
```

**VMware:**
```
File → Export to OVF/OVA
```

### Import VM

Il cliente può importare il file `.ova` con un doppio click o:

```bash
# VirtualBox
VBoxManage import sentinelcore-v1.0.ova

# VMware
# File → Open → sentinelcore-v1.0.ova
```

## Supporto

Per problemi o domande:
- Repository: https://github.com/Dognet-Technologies/sentinelcore
- Issues: https://github.com/Dognet-Technologies/sentinelcore/issues
