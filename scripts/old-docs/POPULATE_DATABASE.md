# 📊 Guida Popolamento Database SentinelCore

Questo documento spiega come popolare il database SentinelCore con dati di test completi per testare tutte le funzionalità del frontend.

## 📦 Cosa Include lo Script

Lo script `populate-test-data.sql` popola **TUTTE** le 21 tabelle del database con dati realistici:

### 👥 **Utenti e Autenticazione (5 utenti)**
- ✅ 5 utenti con ruoli diversi (admin, team_leader, user)
- ✅ 2 sessioni attive
- ✅ 2 API keys
- ✅ 5 configurazioni notifiche utente
- ✅ 4 eventi reputazione

### 👨‍👩‍👧‍👦 **Team (4 team)**
- ✅ 4 team con webhook Slack/Telegram
- ✅ 8 assegnazioni membri ai team

### 💻 **Asset IT (12 asset)**
- ✅ Server (web, database, application, docker, backup)
- ✅ Network devices (firewall, switch, load balancer)
- ✅ Workstation (Windows, macOS)
- ✅ IoT devices (printer, CCTV camera)
- ✅ Cloud VM (AWS)

### 🐛 **Vulnerabilità (25 vulnerabilità)**
- ✅ 3 Critical (SQL Injection, RCE, Unauth DB Access)
- ✅ 5 High (XSS, Weak SSL, Default Creds, etc.)
- ✅ 6 Medium (Info disclosure, Missing headers, etc.)
- ✅ 2 Low (Verbose banner, Missing rate limiting, etc.)
- ✅ 2 Info (Outdated jQuery, Robots.txt)
- ✅ Vari stati: open, in_progress, resolved, closed
- ✅ 4 risoluzioni complete con note

### 🌐 **Network Discovery (12 dispositivi + 12 link)**
- ✅ 3 network scan completati
- ✅ 12 dispositivi scoperti con MAC, OS, porte aperte, servizi
- ✅ 12 collegamenti topologia rete (star topology)

### 📄 **Report (5 report)**
- ✅ Report mensili, export CSV, executive summary
- ✅ Report in vari formati (PDF, CSV, XML, JSON)
- ✅ Stati: completed, processing

### 🔌 **Plugin (4 plugin)**
- ✅ Nessus Importer (import)
- ✅ Slack Notifier (notification)
- ✅ PDF Report Generator (export)
- ✅ CVSS Calculator (analysis)

### 🔒 **Sicurezza**
- ✅ 3 IP whitelisted (office, VPN, auditor)
- ✅ 2 permessi granulari utente

### 📧 **Notifiche (6 notifiche)**
- ✅ Email, Slack, Telegram
- ✅ Stati: sent, pending

### 📋 **Audit Log (10 eventi)**
- ✅ Create, Update, Delete su varie entità
- ✅ Tracking IP e user agent

### ⚙️ **Remediation (3 task)**
- ✅ Stati: pending, completed, failed
- ✅ Script di remediation con output

---

## 🚀 Come Eseguire lo Script

### **Prerequisito: PostgreSQL Attivo**

Prima verifica che PostgreSQL sia in esecuzione:

```bash
pg_isready -h localhost
```

Se non risponde, avvia PostgreSQL:
```bash
sudo service postgresql start
# OPPURE
sudo systemctl start postgresql
```

### **Opzione 1: Esecuzione Diretta (Consigliata)**

```bash
cd /home/user/sentinelcore

# Esegui lo script
psql -h localhost -U vlnman -d vulnerability_manager -f populate-test-data.sql
```

### **Opzione 2: Con Password da Config**

```bash
# Password dalla configurazione: DogNET
PGPASSWORD=DogNET psql -h localhost -U vlnman -d vulnerability_manager -f populate-test-data.sql
```

### **Opzione 3: Usando URL Completo**

```bash
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" -f populate-test-data.sql
```

---

## ✅ Verifica Popolamento

Dopo l'esecuzione, vedrai un riepilogo:

```
 table_name           | records
----------------------+---------
 Audit Logs          |      10
 Assets              |      12
 Network Devices     |      12
 Network Links       |      12
 Network Scans       |       3
 Notifications       |       6
 Plugins             |       4
 Remediation Tasks   |       3
 Reports             |       5
 Teams               |       4
 Users               |       5
 Vulnerabilities     |      25
```

---

## 🔑 Credenziali di Test

Usa queste credenziali per fare login nel frontend:

| Username | Password   | Ruolo        | Note                           |
|----------|------------|--------------|--------------------------------|
| admin    | Admin123!  | admin        | Accesso completo               |
| jdoe     | User123!   | team_leader  | Leader Security Team + DevOps  |
| asmith   | User123!   | user         | Utente standard con 2FA        |
| bjones   | User123!   | team_leader  | Leader Network Team            |
| cdavis   | User123!   | user         | Utente standard recente        |

**⚠️ ATTENZIONE:** Queste password sono hash di esempio. In produzione genera nuovi hash con Argon2!

---

## 🧪 Cosa Testare nel Frontend

Con questi dati puoi testare:

### **Dashboard** (`/dashboard`)
- ✅ Statistiche vulnerabilità (3 critical, 5 high, 6 medium, 2 low, 2 info)
- ✅ Grafici trend nel tempo
- ✅ Top asset vulnerabili
- ✅ Performance team
- ✅ Recent activity feed

### **Vulnerabilità** (`/vulnerabilities`)
- ✅ Lista 25 vulnerabilità con filtri
- ✅ Stati: open (17), in_progress (4), resolved (3), closed (1)
- ✅ Severity: critical, high, medium, low, info
- ✅ Dettagli CVE, CVSS, EPSS
- ✅ Asset correlati

### **Le Mie Attività** (`/discovery`)
- ✅ Vulnerabilità assegnate all'utente loggato
- ✅ Raggruppamento per host
- ✅ Azioni: Inizia, Risolto

### **Network Discovery** (`/network`)
- ✅ Visualizzazione topologia 12 dispositivi
- ✅ Collegamenti star topology (gateway→devices)
- ✅ Device types colorati (router, server, workstation, printer, IoT)
- ✅ Click su nodo → dettagli completi
- ✅ 3 scan history

### **Host / Assets** (`/hosts`)
- ✅ 12 asset IT di vari tipi
- ✅ Filtri per tipo, location, owner
- ✅ Tags, note, sistema operativo

### **Team** (`/teams`)
- ✅ 4 team con membri
- ✅ Contact email, Slack, Telegram
- ✅ Assegnazioni vulnerabilità

### **Utenti** (`/users`)
- ✅ 5 utenti con ruoli diversi
- ✅ Reputation score
- ✅ 2FA status
- ✅ Sessioni attive
- ✅ API keys

### **Plugin** (`/plugins`)
- ✅ 4 plugin di vari tipi
- ✅ Enabled/disabled status
- ✅ Configurazioni JSON

### **Report** (`/reports`)
- ✅ 5 report generati
- ✅ Formati: PDF, CSV, XML, JSON
- ✅ Download (file path simulato)

### **Settings** (`/settings`)
- ✅ Notification settings personalizzati
- ✅ Security settings (2FA)
- ✅ API keys gestione
- ✅ Sessioni attive

### **Audit Log** (se presente in UI)
- ✅ 10 eventi con vecchi/nuovi valori
- ✅ IP tracking, user agent

---

## 🧹 Pulizia Dati (Opzionale)

Se vuoi ricominciare da zero, decomment le righe TRUNCATE nello script:

```sql
-- Rimuovi i commenti da queste righe:
TRUNCATE TABLE audit_logs, notifications, reputation_events, ...;
```

Oppure esegui manualmente:

```bash
psql -h localhost -U vlnman -d vulnerability_manager -c "TRUNCATE TABLE vulnerabilities CASCADE;"
```

---

## 🐛 Troubleshooting

### Errore: "Connection refused"
```bash
# Verifica PostgreSQL attivo
sudo service postgresql status
sudo service postgresql start
```

### Errore: "password authentication failed"
```bash
# Verifica credenziali in config/default.yaml
# Password di default: DogNET
```

### Errore: "relation does not exist"
```bash
# Esegui prima le migrazioni
cd /home/user/sentinelcore
./run-migrations.sh
```

### Errore: "duplicate key value violates unique constraint"
```bash
# Hai già dati nel database
# Usa TRUNCATE prima di eseguire lo script
# Oppure skippa le righe duplicate
```

---

## 📊 Dati Statistici Inseriti

| Categoria              | Quantità |
|------------------------|----------|
| Utenti                 | 5        |
| Team                   | 4        |
| Asset IT               | 12       |
| Vulnerabilità          | 25       |
| Network Devices        | 12       |
| Network Links          | 12       |
| Network Scans          | 3        |
| Report                 | 5        |
| Plugin                 | 4        |
| Notifiche              | 6        |
| Audit Log              | 10       |
| Remediation Task       | 3        |
| User Sessions          | 2        |
| API Keys               | 2        |
| IP Whitelist           | 3        |
| User Permissions       | 2        |
| Reputation Events      | 4        |
| Resolutions            | 4        |
| **TOTALE RECORD**      | **~120** |

---

## 🎯 Prossimi Passi

1. ✅ Popola il database con questo script
2. ✅ Avvia il backend: `cd vulnerability-manager && cargo run`
3. ✅ Avvia il frontend: `cd vulnerability-manager-frontend && npm start`
4. ✅ Login con `admin / Admin123!`
5. ✅ Testa TUTTE le pagine!
6. ✅ Identifica cosa manca o non funziona

---

## 📝 Note

- **Hash Password:** Gli hash Argon2 nello script sono placeholder. In produzione usa hash reali.
- **File Path:** I path dei report e plugin sono simulati (`/reports/`, `/plugins/`)
- **Network Interface:** Ricorda di configurare l'interfaccia corretta in `config/default.yaml`
- **Backup:** Prima di popolare, considera un backup del database esistente

---

**Buon Testing! 🚀**
