# SentinelCore - Deployment Guide

Questa guida fornisce **3 metodi** per deployare SentinelCore in produzione.

---

## 🎯 Metodo 1: Pacchetto .deb (Consigliato)

**Vantaggi:**
- ✅ Installazione con un solo comando
- ✅ Integrazione nativa con systemd
- ✅ Facile aggiornamento con `apt`
- ✅ Rimozione pulita con `apt remove`

### Prerequisiti
- Debian 12/13 o Ubuntu 22.04/24.04
- Rust e Node.js installati sul sistema di build
- Accesso root per l'installazione

### Build del pacchetto

```bash
# 1. Clona il repository
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore

# 2. Checkout alla branch con P1-P5 implementate
git checkout claude/sentinelcore-production-review-012z1oZTPpQQ9yXf1tJMBVmM

# 3. Rendi eseguibile lo script
chmod +x build-deb.sh

# 4. Esegui il build
./build-deb.sh
```

Questo creerà `sentinelcore_1.0.0_amd64.deb`

### Installazione

```bash
# Installa il pacchetto
sudo dpkg -i sentinelcore_1.0.0_amd64.deb

# Se ci sono dipendenze mancanti
sudo apt-get install -f
```

### Configurazione post-installazione

```bash
# 1. Genera JWT secret
openssl rand -hex 32

# 2. Modifica configurazione
sudo nano /opt/sentinelcore/.env

# Imposta:
# - VULN_AUTH_SECRET_KEY=<il_secret_generato>
# - DATABASE_URL con password sicura

# 3. Cambia password PostgreSQL
sudo -u postgres psql
ALTER USER vlnman WITH PASSWORD 'your_secure_password';
\q

# 4. Riavvia servizio
sudo systemctl restart sentinelcore

# 5. Verifica stato
sudo systemctl status sentinelcore
```

### Accesso

Apri il browser: `http://YOUR_SERVER_IP`

---

## 🖥️ Metodo 2: VM Debian 13 (Più semplice)

**Vantaggi:**
- ✅ Setup completamente automatico
- ✅ Un solo script fa tutto
- ✅ Ideale per ambienti VM/Cloud

### Prerequisiti
- VM con Debian 13 (Trixie) installata
- Accesso SSH come root
- Connessione Internet

### Installazione

```bash
# 1. Connettiti alla VM
ssh root@your-vm-ip

# 2. Scarica lo script
wget https://raw.githubusercontent.com/Dognet-Technologies/sentinelcore/claude/sentinelcore-production-review-012z1oZTPpQQ9yXf1tJMBVmM/vm-setup-debian13.sh

# 3. Rendi eseguibile
chmod +x vm-setup-debian13.sh

# 4. Esegui (ci vogliono 10-15 minuti)
./vm-setup-debian13.sh
```

Lo script:
- Installa tutte le dipendenze
- Compila backend e frontend
- Configura PostgreSQL
- Esegue le migrations
- Configura Nginx
- Avvia i servizi

### Post-installazione

```bash
# 1. Genera JWT secret
openssl rand -hex 32

# 2. Modifica configurazione
sudo nano /opt/sentinelcore/.env

# 3. Riavvia
sudo systemctl restart sentinelcore
```

---

## 🐳 Metodo 3: Docker (Non raccomandato)

**⚠️ ATTENZIONE**: Il deployment Docker ha problemi con le versioni di Rust.
**Consigliamo Metodo 1 o 2**.

Se vuoi comunque provare Docker:

```bash
git clone https://github.com/Dognet-Technologies/sentinelcore.git
cd sentinelcore
cp .env.production.example .env
# Modifica .env con i tuoi segreti
docker-compose up -d
```

**Problemi noti:**
- Dipendenze Rust richiedono versioni future (1.85-1.88)
- Build può fallire con errori MSRV
- Tempi di compilazione molto lunghi

---

## 🔧 Gestione del servizio

### Comandi systemd

```bash
# Stato
sudo systemctl status sentinelcore

# Start/Stop/Restart
sudo systemctl start sentinelcore
sudo systemctl stop sentinelcore
sudo systemctl restart sentinelcore

# Logs
sudo journalctl -u sentinelcore -f

# Log degli ultimi errori
sudo journalctl -u sentinelcore -p err
```

### Database

```bash
# Accedi a PostgreSQL
sudo -u postgres psql -d vulnerability_manager

# Backup
sudo -u postgres pg_dump vulnerability_manager > backup.sql

# Restore
sudo -u postgres psql -d vulnerability_manager < backup.sql
```

### Nginx

```bash
# Testa configurazione
sudo nginx -t

# Reload
sudo systemctl reload nginx

# Log access
sudo tail -f /var/log/nginx/access.log

# Log errors
sudo tail -f /var/log/nginx/error.log
```

---

## 🔒 Sicurezza

### Checklist post-installazione

- [ ] Cambiato `VULN_AUTH_SECRET_KEY` con valore random
- [ ] Cambiata password database PostgreSQL
- [ ] Cambiata password admin di default
- [ ] Configurato firewall (UFW)
- [ ] Configurato fail2ban
- [ ] Abilitato HTTPS con Let's Encrypt
- [ ] Backup automatico database configurato

### Setup HTTPS (Let's Encrypt)

```bash
# Installa certbot
sudo apt-get install certbot python3-certbot-nginx

# Ottieni certificato
sudo certbot --nginx -d yourdomain.com

# Auto-renewal è automatico
```

---

## 📊 Monitoring

### Health check endpoint

```bash
# Verifica che il backend risponda
curl http://localhost:8080/api/health
```

### Metriche

```bash
# Prometheus metrics (porta 9090)
curl http://localhost:9090/metrics
```

---

## 🆘 Troubleshooting

### Backend non si avvia

```bash
# Verifica logs
sudo journalctl -u sentinelcore -n 100

# Verifica .env
sudo cat /opt/sentinelcore/.env

# Verifica database connection
sudo -u postgres psql -d vulnerability_manager -c "SELECT 1"
```

### Frontend non carica

```bash
# Verifica Nginx
sudo nginx -t
sudo systemctl status nginx

# Verifica files
ls -la /opt/sentinelcore/vulnerability-manager-frontend/build/
```

### Database errors

```bash
# Verifica PostgreSQL
sudo systemctl status postgresql

# Verifica connessione
psql -h localhost -U vlnman -d vulnerability_manager

# Ri-esegui migrations
cd /opt/sentinelcore/vulnerability-manager/migrations
for f in *.sql; do sudo -u postgres psql -d vulnerability_manager -f "$f"; done
```

---

## 📈 Performance

### PostgreSQL tuning

```bash
# Edit PostgreSQL config
sudo nano /etc/postgresql/15/main/postgresql.conf

# Suggerimenti:
shared_buffers = 256MB
effective_cache_size = 1GB
max_connections = 100
```

### Nginx caching

Già configurato nel setup script per caching di static assets.

---

## 🔄 Aggiornamenti

### Metodo 1 (.deb)

```bash
# Scarica nuovo .deb
wget https://releases.sentinelcore.com/sentinelcore_1.1.0_amd64.deb

# Aggiorna
sudo dpkg -i sentinelcore_1.1.0_amd64.deb
sudo systemctl restart sentinelcore
```

### Metodo 2 (VM)

```bash
cd /opt/sentinelcore
git pull origin claude/sentinelcore-production-review-012z1oZTPpQQ9yXf1tJMBVmM

# Ricompila
cd vulnerability-manager
cargo build --release
cd ../vulnerability-manager-frontend
npm run build
cd ..

# Riavvia
sudo systemctl restart sentinelcore
```

---

## 📞 Supporto

- **GitHub Issues**: https://github.com/Dognet-Technologies/sentinelcore/issues
- **Email**: info@dognet.tech
- **Documentazione**: https://docs.sentinelcore.com

---

## 📄 Licenza

Vedere LICENSE file nel repository.
