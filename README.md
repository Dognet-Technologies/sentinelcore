# Descrizione del Server - Sentinel Core
![Screenshot_dash](https://github.com/user-attachments/assets/ad44f731-de3f-4e23-9c53-9023f74de136)
LEGGERE ATTENTAMENTE:
I sorgenti sono disponibili ma il sistema non è stabile, allo stato attuale se compili il backend in rust ci sono ancora errori da risolvere.
Il sistema ad ora è instabile, ma se vuoi questo può essere già un ottimo punto di partenza dal quale partire.

## Architettura del Sistema

Il server **Sentinel Core** è un sistema di gestione vulnerabilità enterprise-grade sviluppato in **Rust** con database **PostgreSQL**, progettato per automatizzare il processo di vulnerability management e remediation coordination.

![Screenshot_vulns](https://github.com/user-attachments/assets/afa271c4-2325-4def-aa50-b0d5808de6c1)

## Flusso Operativo

### 1. Acquisizione Vulnerabilità
Il server riceve tramite **API REST** informazioni sulle vulnerabilità da diversi tool di security testing:

**Tool Supportati:**
- **Nessus** (Tenable)
- **Nexpose** (Rapid7)
- **OpenVAS** 
- **Qualys VMDR**
- **Burp Suite Enterprise**
- **Nmap** (con script NSE)
- **Nikto**
- **OWASP ZAP**
- **Acunetix**
- **Greenbone**
- **Tool personalizzati** via plugin

### 2. Catalogazione e Analisi
Le vulnerabilità vengono **catalogate e organizzate** secondo standard internazionali:

**Metriche di Classificazione:**
- **CVSS Score** (Common Vulnerability Scoring System) - Gravità tecnica
- **EPSS Score** (Exploit Prediction Scoring System) - Probabilità di exploit
- **CVE ID** - Identificativo vulnerabilità
- **CWE ID** - Categoria debolezza
- **Severity levels**: Critical, High, Medium, Low, Info

**Enrichment Automatico:**
- Correlazione con database CVE/NVD
- Mapping asset e servizi
- Geolocalizzazione IP
- Identificazione OS e servizi
- Timeline discovery

### 3. Prioritizzazione Intelligente
Il sistema implementa un **algoritmo di prioritizzazione** che considera:

**Fattori di Rischio:**
- **Business Impact** - Criticità asset per business
- **Exploitability** - Facilità di exploit (EPSS)
- **Asset Exposure** - Esposizione pubblica/interna
- **Patch Availability** - Disponibilità fix
- **Remediation Effort** - Complessità intervento

**Output Prioritizzazione:**
- **Risk Score composito**
- **Remediation timeline suggerita**
- **Effort estimation**
- **Business impact assessment**

### 4. Reportistica e Dashboards
Vengono preparati **grafici e dashboard** per diversi stakeholder:

**Dashboard Executive:**
- Trend vulnerabilità nel tempo
- Metriche KPI (MTTR, SLA compliance)
- Risk exposure evolution
- Team performance metrics
- Budget impact analysis

**Dashboard Operativo:**
- Vulnerabilità per team
- Workload distribution
- Remediation status
- Upcoming deadlines
- Resource allocation

**Report Tecnici:**
- Dettaglio vulnerabilità
- Proof of Concept
- Remediation steps
- Verification procedures
- Rollback plans

### 5. Team Assignment e Workflow
Le **remediation vengono assegnate** ai team competenti:

**Workflow Automatizzato:**
- **Assignment rules** basate su:
  - Tipo di asset (Server, Network, Application)
  - Tecnologia coinvolta (OS, Database, Web)
  - Competenze team
  - Carico di lavoro corrente
  - SLA requirements

**Team Coordination:**
- **Notification automatiche** (Slack, Telegram, Email)
- **Task tracking** con scadenze
- **Progress monitoring**
- **Escalation automatica** su ritardi
- **Approval workflow** per cambiamenti critici

### 6. Integrazione SOAR
Il sistema si integra con piattaforme **SOAR** (Security Orchestration, Automation and Response):

**Integrazioni Supportate:**
- **Phantom/Splunk SOAR**
- **Demisto/Cortex XSOAR**
- **IBM Resilient**
- **Rapid7 InsightConnect**
- **Microsoft Sentinel**
- **Google Chronicle SOAR**

**Automazioni SOAR:**
- **Ticket creation** automatica (ServiceNow, Jira)
- **Playbook execution** per remediation standard
- **Evidence collection** automatica
- **Compliance reporting**
- **Incident response** orchestration

## Caratteristiche Tecniche

### Performance
- **Concurrent processing** di migliaia di vulnerabilità
- **Real-time updates** via WebSocket
- **Caching intelligente** per query frequenti
- **Async processing** per operazioni pesanti

### Scalabilità
- **Microservices-ready** architecture
- **Horizontal scaling** supportato
- **Database sharding** configurabile
- **Load balancing** integrato

### Sicurezza
- **Zero-trust** architecture
- **End-to-end encryption**
- **Audit logging** completo
- **RBAC** granulare
- **OWASP compliance**

### Affidabilità
- **High availability** (99.9% uptime)
- **Disaster recovery** automatico
- **Data backup** continuo
- **Health monitoring** proattivo
- **Graceful degradation**

## Plugin Ecosystem

### Plugin Architecture
Il sistema supporta un **ecosistema di plugin** estensibile:

**Tipi di Plugin:**
- **Import plugins** - Connettori tool esterni
- **Export plugins** - Formati export personalizzati
- **Notification plugins** - Canali notifica custom
- **Analysis plugins** - Algoritmi analisi custom
- **Integration plugins** - Connector sistemi terzi
- **Workflow plugins** - Processi business custom

**Plugin Development:**
- **SDK completo** per sviluppatori
- **Sandbox sicuro** per esecuzione
- **Plugin marketplace** interno
- **Version management** automatico
- **A/B testing** per plugin

# Backend - Sentinel Core

## Informazioni sul Backend

- **Database**: **PostgreSQL** (con UUID extension)
- **Framework**: Axum (Rust) 
- **API**: REST API con autenticazione JWT
- **Porta**: 8080 (configurabile)

## Architettura Utenti

Il sistema implementa un sistema di autorizzazione a tre livelli:

1. **Admin** - Accesso completo al sistema
   - Gestione utenti (CRUD)
   - Gestione vulnerabilità (CRUD)
   - Gestione team e membri
   - Gestione asset e report
   - Gestione plugin
   - Configurazione sistema

2. **Team Leader** - Gestione team e vulnerabilità assegnate
   - Visualizzazione vulnerabilità
   - Gestione del proprio team
   - Creazione e gestione report
   - Accesso ai plugin autorizzati

3. **User** - Accesso base in sola lettura
   - Visualizzazione vulnerabilità assegnate
   - Visualizzazione report
   - Accesso al proprio profilo

## Database PostgreSQL

### Tabelle Principali

- **users** - Gestione utenti con ruoli
- **teams** - Definizione team di remediation  
- **team_members** - Membri dei team
- **vulnerabilities** - Catalogazione vulnerabilità
- **assets** - Inventario asset IT
- **reports** - Report di scansione e analisi
- **plugins** - Sistema plugin estensibile
- **notifications** - Sistema notifiche multi-canale

### Caratteristiche Database

- **UUID** come chiavi primarie per sicurezza
- **Enum types** per status e categorie
- **JSONB** per configurazioni flessibili
- **Timestamp con timezone** per audit trail
- **Indici ottimizzati** per performance
- **Vincoli referenziali** per integrità dati

## Funzionalità Implementate

### Sistema di Vulnerabilità
- Import da tool esterni (Nessus, OpenVAS, Qualys, Burp, ecc.)
- Classificazione CVSS/EPSS
- Stati di remediation (Open, In Progress, Resolved, Closed)
- Assegnazione automatica ai team

### Sistema di Reporting
- Grafici e metriche prioritizzate
- Export multipli formati (XML, JSON, CSV, PDF)
- Analisi trend temporali
- Dashboard executive

### Sistema di Notifiche
- Integrazione Slack/Telegram
- Email automatiche
- Webhook personalizzabili
- Allerte basate su soglie

### Sistema Plugin
- Plugin community e custom
- Supporto multi-linguaggio
- Configurazione dinamica
- Sandbox sicuro

## Configurazione Database

### Connection String
```
postgres://vlnman:DogNET@localhost/vulnerability_manager
```

### Pool Connections
- Max connections: 5 (configurabile)
- Timeout: 30s
- Idle timeout: 10min

## API Endpoints

### Autenticazione
- `POST /api/auth/login` - Login utente
- `GET /api/health` - Health check

### Gestione Utenti (Admin)
- `GET /api/users` - Lista utenti
- `POST /api/users` - Crea utente
- `GET /api/users/:id` - Dettaglio utente
- `PUT /api/users/:id` - Aggiorna utente
- `DELETE /api/users/:id` - Elimina utente
- `GET /api/users/me` - Profilo corrente

### Gestione Vulnerabilità
- `GET /api/vulnerabilities` - Lista vulnerabilità
- `POST /api/vulnerabilities` - Crea vulnerabilità
- `GET /api/vulnerabilities/:id` - Dettaglio vulnerabilità
- `PUT /api/vulnerabilities/:id` - Aggiorna vulnerabilità
- `DELETE /api/vulnerabilities/:id` - Elimina vulnerabilità
- `POST /api/vulnerabilities/:id/assign` - Assegna a team

### Gestione Team
- `GET /api/teams` - Lista team
- `POST /api/teams` - Crea team
- `GET /api/teams/:id` - Dettaglio team
- `PUT /api/teams/:id` - Aggiorna team
- `DELETE /api/teams/:id` - Elimina team
- `GET /api/teams/:id/members` - Membri team
- `POST /api/teams/:id/members` - Aggiungi membro
- `DELETE /api/teams/:id/members/:member_id` - Rimuovi membro

### Gestione Asset
- `GET /api/assets` - Lista asset
- `POST /api/assets` - Crea asset
- `GET /api/assets/:id` - Dettaglio asset
- `PUT /api/assets/:id` - Aggiorna asset
- `DELETE /api/assets/:id` - Elimina asset

### Gestione Report
- `GET /api/reports` - Lista report
- `POST /api/reports` - Crea report
- `GET /api/reports/:id` - Dettaglio report
- `PUT /api/reports/:id` - Aggiorna report
- `DELETE /api/reports/:id` - Elimina report
- `GET /api/reports/:id/download` - Download report

### Gestione Plugin
- `GET /api/plugins` - Lista plugin
- `POST /api/plugins` - Installa plugin
- `GET /api/plugins/:id` - Dettaglio plugin
- `PUT /api/plugins/:id` - Aggiorna plugin
- `DELETE /api/plugins/:id` - Disinstalla plugin
- `POST /api/plugins/:id/toggle` - Abilita/Disabilita
- `POST /api/plugins/:id/execute` - Esegui plugin
- `POST /api/plugins/scan` - Scansione plugin

## Sicurezza Implementata

### Autenticazione & Autorizzazione
- **JWT Token** con scadenza configurabile
- **Password policy** robusta (OWASP-compliant)
- **Argon2** per hashing password
- **Role-based access control** (RBAC)

### Database Security
- **Prepared statements** per prevenire SQL injection
- **UUID** invece di ID incrementali
- **Validazione input** su tutti gli endpoint
- **Rate limiting** configurabile

### Network Security
- **CORS** configurato correttamente
- **HTTPS ready** per produzione
- **Token validation** su ogni richiesta protetta

## Deployment

### Sviluppo
```bash
# Avvia database PostgreSQL
sudo systemctl start postgresql

# Avvia backend
cd backend
cargo run

# Server disponibile su http://localhost:8080
```

### Produzione
- Docker container supportato
- Reverse proxy (nginx/traefik)
- SSL/TLS certificati
- Environment-based configuration
- Health checks integrati
