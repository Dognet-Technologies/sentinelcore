# 🚀 START HERE - Guida Rapida

## ✅ Il tuo database è già configurato!

**Configurazione esistente:**
- Database: `vulnerability_manager`
- User: `vlnman`
- Password: `DogNET`

Non serve ricreare l'utente o il database. Segui questi passaggi:

---

## 📋 PASSAGGI PER AVVIARE

### 1️⃣ Avvia PostgreSQL

```bash
sudo systemctl start postgresql
```

### 2️⃣ Verifica quali migrations servono

```bash
./check-migrations.sh
```

Questo script ti dirà esattamente quali tabelle mancano.

### 3️⃣ Esegui solo le migrations mancanti

**Se hai già le tabelle base** (users, vulnerabilities, etc.):

```bash
# Esegui SOLO la nuova migration per Network Topology
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -f vulnerability-manager/migrations/003_network_topology.sql
```

**Se il database è vuoto** (prima installazione):

```bash
# Esegui tutte le migrations
./run-migrations.sh
```

### 4️⃣ Avvia l'applicazione

**Metodo semplice (Menu interattivo):**
```bash
./start.sh
```

Seleziona opzione 5 per avviare tutto insieme.

**Oppure manuale:**

Terminal 1:
```bash
./start-backend.sh
```

Terminal 2:
```bash
./start-frontend.sh
```

---

## 🌐 Accedi all'applicazione

- **Frontend:** http://localhost:3000
- **Backend API:** http://localhost:8080

**Credenziali default** (se hai eseguito seed_data.sql):
- Username: `admin`
- Password: `Admin123!`

---

## 🆕 Nuove Feature da Testare

### Network Scan Visualization

1. Vai su http://localhost:3000
2. Naviga alla sezione "Network Scan"
3. Click su "Start Scan" (icona ▶️)
4. Visualizza la topologia grafica
5. **Click destro** su un device
6. Seleziona "Fix Vulnerabilities"

### Export Report

Esporta report in 4 formati:
- PDF (con grafici)
- XML (strutturato)
- JSON (API-ready)
- CSV (Excel-ready)

### Notifiche

Configura notifiche Slack/Telegram/Email nei settings dei team.

---

## 🐛 Problemi?

### PostgreSQL non parte
```bash
sudo systemctl status postgresql
# Se non è installato:
sudo apt install postgresql
```

### Errori di compilazione backend
```bash
cd vulnerability-manager
export SQLX_OFFLINE=true
cargo build
```

### Frontend non si avvia
```bash
cd vulnerability-manager-frontend
rm -rf node_modules
npm install
npm start
```

---

## 📚 Guide Complete

- **QUICKSTART.md** - Guida dettagliata completa
- **check-migrations.sh** - Verifica stato database
- **start.sh** - Menu interattivo per tutto

---

**Quick Start:**
```bash
sudo systemctl start postgresql  # Avvia DB
./check-migrations.sh            # Verifica stato
./start.sh                       # Avvia app (opzione 5)
```

Fatto! 🎉
