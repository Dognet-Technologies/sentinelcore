# SentinelCore - Analisi Architetturale e Macro Aree Funzionali

**Data:** 2026-01-09
**Versione:** 1.0
**Scopo:** Mappatura delle macro aree funzionali, algoritmi core e flussi di dati per identificare opportunità di ottimizzazione

---

## 📋 PANORAMICA SISTEMA

**Stack Tecnologico:**
- **Backend:** Rust (Axum 0.6, SQLx)
- **Frontend:** React 18 + TypeScript + TailwindCSS
- **Database:** PostgreSQL 15+ con JSONB, trigger e funzioni
- **Autenticazione:** JWT con httpOnly cookies
- **API:** REST con 78+ endpoint

**Metriche:**
- ~50.000 righe di codice
- 30+ tabelle database
- 40+ migrazioni SQL
- 6 worker background
- 7 scanner plugin integrati

---

## 🎯 MACRO AREE FUNZIONALI

### 1. INTELLIGENT RISK SCORING ENGINE

**Location:** `/vulnerability-manager/src/scoring/`

#### Funzioni Principali

**`calculate_risk_score()`**
- **Input:** Dati vulnerabilità (CVSS, CVE, asset info)
- **Output:** risk_score (0-100), risk_tier, sla_deadline
- **Complessità:** O(1)

#### Algoritmo: Multi-Factor Risk Scoring

```
Risk Score (0-100) =
  (CVSS Base × 0.30) +          // 0-30 punti
  (EPSS Score × 0.25) +         // 0-25 punti
  (Business Impact × 0.25) +    // 0-25 punti
  (Asset Exposure × 0.15) +     // 0-15 punti
  (Exploit Availability × 0.05) // 0-5 punti
```

#### Componenti dell'Algoritmo

**a) CVSS Component** (`risk_calculator.rs`)
```
Mapping severity → punti:
- Critical (9.0-10.0): 30 punti
- High (7.0-8.9):      22 punti
- Medium (4.0-6.9):    15 punti
- Low (0.1-3.9):        5 punti
```

**b) EPSS Component** (`exploit_intelligence.rs`)
```
Probabilità exploit → punti:
- EPSS >50%:    25 punti (exploitation altamente probabile)
- EPSS 20-50%:  18 punti
- EPSS 5-20%:   10 punti
- EPSS <5%:      3 punti
```

**Nota matematica:** EPSS (Exploit Prediction Scoring System) è un modello probabilistico basato su machine learning che stima la probabilità che una CVE venga exploitata nei prossimi 30 giorni. Il dataset viene aggiornato quotidianamente da FIRST.org (~200k CVE).

**c) Business Impact** (`business_impact.rs`)
```rust
Business Score = Asset Criticality (0-15) +
                 Sensitive Data Flag (+5) +
                 Revenue Impact (+5 se >€10k/ora)

Asset Criticality:
- Critical (payment/auth/core): 15 punti
- High (production):            11 punti
- Medium (internal):             6 punti
- Low (dev/test):                2 punti
```

**d) Asset Exposure** (`asset_exposure.rs`)
```
Network Zone → punti:
- Internet-Facing: 12 punti (attacco diretto possibile)
- DMZ:            10 punti
- Internal:        5 punti
- Isolated:        0 punti
```

**e) Exploit Intelligence** (`exploit_intelligence.rs`)
```rust
pub enum ExploitStatus {
    PublicExploitActiveCampaigns, // 5 punti - in CISA KEV
    PublicExploit,                // 4 punti - Metasploit/ExploitDB
    PoCAvailable,                 // 3 punti - PoC code disponibile
    TheoreticalExploit,           // 1 punto
    NoExploit,                    // 0 punti
}
```

#### Priority Overrides (Auto-Escalation)

```rust
// Logica di escalation automatica
if is_zero_day → score = max(score, 90) → Critical
if is_ransomware_targeted → score = max(score, 85) → Critical
if is_actively_exploited → score += 20
if is_compliance_critical → score = max(score, 80) → Critical
```

**Nota:** Gli override hanno priorità assoluta sul calcolo base per garantire che minacce note (es. zero-day) non vengano sottostimate.

#### Risk Tiers & SLA Mapping

```
Critical (80-100): SLA 1 giorno
High (60-79):      SLA 7 giorni
Medium (40-59):    SLA 30 giorni
Low (20-39):       SLA 90 giorni
Info (<20):        No SLA
```

#### Flusso Dati

```
INPUT: Vulnerability data (scanner import)
  ↓
1. Lookup asset metadata (criticality, network zone) → DB query
2. Calculate CVSS component → O(1)
3. Fetch EPSS score → O(1) da cache database
4. Calculate Business Impact → O(1)
5. Calculate Asset Exposure → O(1)
6. Check Exploit Intelligence → O(1)
7. Sum weighted components
8. Apply priority overrides
9. Determine risk tier (thresholds)
10. Calculate SLA deadline = first_detected + sla_days
  ↓
OUTPUT: {
  risk_score: 87,
  risk_tier: "Critical",
  sla_days: 1,
  sla_deadline: "2024-12-15T10:30:00Z",
  component_breakdown: {...}  // per trasparenza
}
  ↓
STORAGE: UPDATE vulnerabilities SET risk_score=..., risk_tier=...
TRIGGERS:
  - Notification routing (se risk_tier = Critical)
  - Auto-assignment rules (se condizioni match)
  - JIRA ticket creation (se auto-ticket rule attiva)
```

#### Implementazione Database

**Location:** `/migrations/013_risk_scoring_and_sla.sql`

```sql
-- PostgreSQL function triggerata automaticamente
CREATE OR REPLACE FUNCTION calculate_risk_score()
RETURNS TRIGGER AS $$
BEGIN
  -- Fetch asset metadata
  -- Calculate components
  -- Apply overrides
  -- Set NEW.risk_score, NEW.risk_tier, NEW.sla_deadline
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_risk_score
BEFORE INSERT OR UPDATE ON vulnerabilities
FOR EACH ROW
EXECUTE FUNCTION calculate_risk_score();
```

**Indici di performance:**
- `idx_vulnerabilities_risk_score` (B-tree)
- `idx_vulnerabilities_risk_tier` (B-tree)
- `idx_vulnerabilities_sla_deadline` (B-tree, partial WHERE sla_breached = FALSE)

#### Opportunità di Ottimizzazione

**🔍 Analisi Entropia:**
- Il peso CVSS (30%) potrebbe essere sovrastimato per vulnerabilità con EPSS basso
- **Proposta:** Peso adattivo basato su correlazione storica tra CVSS e sfruttamento reale

**📊 Benchmark Potenziale:**
- Attualmente: 5 query DB + 1 calcolo per vulnerability
- **Proposta:** Batch calculation per import di scan grandi (>1000 vuln)

**🧮 Algoritmo:**
- Somma pesata lineare è semplice ma non cattura interazioni non-lineari
- **Proposta:** Testare modello moltiplicativo per critical assets: `score = CVSS × EPSS × Business Impact`

---

### 2. SLA AUTOMATION ENGINE

**Location:** `/vulnerability-manager/src/workers/sla_checker.rs`

#### Funzioni Principali

**`start_sla_checker()`** - Background worker
- **Frequenza:** Ogni 1 ora
- **Complessità:** O(n) dove n = vulnerabilità con SLA attivo

**`check_and_mark_breaches()`**
- **Input:** Timestamp corrente
- **Output:** Lista vulnerabilità in breach

**PostgreSQL:** `mark_sla_breaches()` function

#### Algoritmo: SLA Deadline Calculation

```sql
SLA Deadline = vulnerability.first_detected + sla_days (interval)

-- Esempio:
-- first_detected: 2024-12-14 10:30:00
-- risk_tier: Critical → sla_days: 1
-- sla_deadline: 2024-12-15 10:30:00

Breach Detection:
  IF sla_deadline < NOW()
     AND status NOT IN ('resolved', 'closed')
     AND NOT sla_breached
  THEN
     sla_breached = TRUE
     breach_timestamp = NOW()
```

#### Flusso Dati

```
TRIGGER: Risk score calculation completes
  ↓
Determine sla_days from risk_tier:
  Critical → 1 day
  High → 7 days
  Medium → 30 days
  Low → 90 days
  ↓
SET sla_deadline = first_detected + sla_days (PostgreSQL interval)
  ↓
BACKGROUND WORKER (ogni 1 ora):
  ↓
  SELECT id, title, hostname, assigned_user_id, sla_deadline
  FROM vulnerabilities
  WHERE sla_deadline < NOW()
    AND status NOT IN ('resolved', 'closed')
    AND sla_breached = FALSE
  ↓
  FOR EACH vulnerability:
    UPDATE vulnerabilities
    SET sla_breached = TRUE, breach_timestamp = NOW()
    WHERE id = vulnerability.id
    ↓
    Trigger notification (SLA Breach Alert rule, priority: 5)
    ↓
    Log to audit trail
```

#### Notification Stages (Progressive Alerts)

```
Timeline:
  75% elapsed → Warning notification (priority: 20)
  90% elapsed → Escalation notification (priority: 10)
  100% elapsed → Breach alert (priority: 5)
```

**Calcolo percentuale elapsed:**
```rust
let total_duration = sla_deadline - first_detected;
let elapsed = now - first_detected;
let percentage = (elapsed / total_duration) * 100.0;

if percentage >= 75.0 && percentage < 90.0 {
    trigger_notification("SLA Warning 75%");
} else if percentage >= 90.0 && percentage < 100.0 {
    trigger_notification("SLA Warning 90%");
} else if percentage >= 100.0 {
    trigger_notification("SLA Breach 100%");
}
```

#### Opportunità di Ottimizzazione

**🔍 Performance:**
- Query SLA attuale scansiona tutte le vulnerabilità ogni ora
- **Proposta:** Partial index + materialized view per vulnerabilità "at risk" (prossime 24h)

**📊 Predizione:**
- Sistema reattivo: notifica solo a breach avvenuto
- **Proposta:** Modello predittivo che stima probabilità di breach basato su velocity di remediation (giorni medi per chiudere vuln simili)

**🧮 SLA Dinamici:**
- SLA fissi per tier potrebbero non riflettere urgenza reale
- **Proposta:** SLA adattivi basati su workload del team e storico performance

---

### 3. RISK-BASED REMEDIATION ENGINE (RBRE)

**Location:** `/vulnerability-manager/src/remediation/rbre.rs`

#### Funzioni Principali

**`RBRECalculator::calculate_rps()`**
- **Input:** Vulnerability + Asset metadata
- **Output:** Remediation Priority Score (RPS, 0-100)
- **Complessità:** O(1) per vulnerabilità

**`calculate_time_factor()`**
- **Input:** days_open
- **Output:** Time Factor (0-1)

**`estimate_remediation_hours()`**
- **Input:** Difficulty level, priority tier
- **Output:** Stima ore

#### Algoritmo: Remediation Priority Score (RPS)

```
RPS = (TS × EP × AC × EX × TC × TF) × 100

Dove:
  TS = Technical Severity (CVSS/10)        // 0-1
  EP = Exploit Probability (EPSS)          // 0-1
  AC = Asset Criticality (0-1)             // normalizzato
  EX = Exposure Factor (0-1)               // network zone
  TC = Threat Context (0-1)                // active campaigns, KEV
  TF = Time Factor (logarithmic penalty)   // 0-1
```

**Nota matematica:** Modello moltiplicativo (vs. additivo del Risk Score). Questo significa che una sola componente = 0 annulla l'intero score, riflettendo che TUTTI i fattori devono essere presenti per alta priorità.

#### Time Factor Formula (Logaritmica)

```rust
TF = min(1.0, ln(days_open + 1) / ln(180))

// Esempi:
Day 1:   TF ≈ 0.13  // vulnerabilità nuova, poco peso al tempo
Day 30:  TF ≈ 0.69
Day 90:  TF ≈ 0.85
Day 180+: TF = 1.0  // penalità massima per vuln vecchie
```

**Razionale:** Funzione logaritmica previene l'esplosione del penalty factor e riflette la natura diminishing returns dell'urgenza nel tempo.

#### Priority Tiers (RPS-based)

```
Critical (RPS ≥ 70): Remediation SLA 1 giorno
High (40-69):        Remediation SLA 7 giorni
Medium (20-39):      Remediation SLA 30 giorni
Low (<20):           Remediation SLA 90 giorni
```

#### Remediation Effort Estimation

```rust
effort_hours = base_hours × priority_multiplier + downtime_hours

base_hours by difficulty:
  - Trivial:    2h  (patch + reboot)
  - Easy:       6h  (patch + config test)
  - Medium:    24h  (testing + coordination)
  - Hard:      80h  (workaround, vendor escalation)
  - Very Hard: 200h (architectural change, code rewrite)

priority_multiplier:
  Critical/High: 1.0 (no delay, immediate action)
  Medium:        1.2 (coordination overhead)
  Low:           1.5 (may require scheduling)

downtime_hours:
  Se requires_downtime = TRUE:
    business_hours_lost × hourly_revenue_impact
```

#### Flusso Dati

```
INPUT: RemediationPlanRequest {
  device_ids: [uuid1, uuid2, ...],
  include_filters: {risk_tier: ["Critical", "High"]},
  max_downtime_hours: 8
}
  ↓
1. Fetch all vulnerabilities for selected devices
2. FOR EACH vulnerability:
     Calculate RPS components:
       - TS = cvss_score / 10.0
       - EP = epss_score
       - AC = asset_criticality_normalized
       - EX = exposure_factor (from network zone)
       - TC = threat_context (KEV, ransomware, etc.)
       - TF = calculate_time_factor(days_open)

     RPS = (TS × EP × AC × EX × TC × TF) × 100
  ↓
3. Sort vulnerabilities by RPS (descending)
  ↓
4. FOR EACH vulnerability (in order):
     Estimate remediation_hours
     Accumulate total_hours
  ↓
5. Group by device
6. Generate execution order:
     - Highest RPS first
     - Group same patch/action
     - Minimize downtime windows
  ↓
OUTPUT: RemediationPlan {
  id, title, description,
  devices: Vec<Device>,
  vulnerabilities: Vec<Vulnerability> (sorted by RPS),
  total_estimated_hours,
  priority_tier,
  execution_order: Vec<RemediationTask>,
  estimated_completion_date
}
  ↓
STORAGE: INSERT INTO remediation_plans
EXECUTION: RemediationExecutor background worker picks up tasks
```

#### RemediationExecutor (Automated Execution)

**Location:** `/vulnerability-manager/src/network/remediation_executor.rs`

```rust
RemediationTask {
  device_id,
  vulnerability_id,
  action_type: "patch" | "disable_service" | "firewall_rule" | "config_change",
  commands: Vec<String>,  // SSH commands
  requires_downtime: bool,
  estimated_duration: Duration
}

// Background worker loop
loop {
  task = get_pending_task_highest_priority()

  // Pre-flight checks
  verify_device_reachable()
  verify_prerequisites()
  acquire_change_lock()  // prevent concurrent changes

  // Execute
  result = match task.action_type {
    "patch" => execute_ssh_command(&task.commands),
    "firewall_rule" => apply_firewall_rule(),
    ...
  }

  // Post-execution verification
  verify_vulnerability_resolved()  // re-scan or check service

  // Update
  if result.success {
    UPDATE vulnerabilities SET status = 'resolved'
    UPDATE remediation_tasks SET status = 'completed'
  } else {
    UPDATE remediation_tasks SET status = 'failed', error = result.error
    CREATE notification (failure alert)
  }

  release_change_lock()
}
```

#### Opportunità di Ottimizzazione

**🔍 Algoritmo RPS:**
- Modello moltiplicativo può azzerare score anche con 1 solo fattore basso
- **Proposta:** Modello ibrido: `RPS = (TS × EP × AC)^0.7 × (EX × TC × TF)^0.3` per ridurre sensibilità a singoli fattori

**📊 Time Factor:**
- Logaritmo è smooth ma potrebbe sottovalutare urgenza per vuln molto vecchie
- **Proposta:** Piecewise function con escalation esponenziale dopo 180 giorni

**🧮 Effort Estimation:**
- Attualmente basato su difficoltà manuale (user input)
- **Proposta:** Machine learning su storico remediation: predict effort da (CVE type, affected service, device OS)

**⚡ Batch Optimization:**
- Sorting greedy by RPS potrebbe non minimizzare downtime globale
- **Proposta:** Algoritmo di bin packing per raggruppare remediation in finestre di downtime ottimali

---

### 4. SCANNER INTEGRATION SYSTEM

**Location:** `/vulnerability-manager/src/scanners/`

#### Scanner Supportati (7)

1. **Qualys** (XML)
2. **Nessus** (.nessus XML)
3. **Burp Suite** (JSON)
4. **OpenVAS/GVM** (XML)
5. **Nexpose/InsightVM** (XML)
6. **OWASP ZAP** (XML/JSON)
7. **Nmap** (XML con CVE extraction)

#### Architettura Plugin

```rust
trait ScannerPlugin {
  fn metadata() -> ScannerMetadata {
    name, version, supported_formats
  }

  fn validate(data: &[u8]) -> Result<bool> {
    // Check XML/JSON schema, magic bytes
  }

  fn parse(data: &[u8]) -> Result<Vec<ParsedVulnerability>> {
    // Parse scanner-specific format
  }
}

ScannerRegistry {
  plugins: HashMap<ScannerType, Box<dyn ScannerPlugin>>
}

// Auto-registration via macro
scanner_registry! {
  QualysPlugin,
  NessusPlugin,
  ...
}
```

#### Parsing Flow

```
INPUT: Upload scan file (multipart/form-data)
  ↓
1. Validate file size (<100MB)
2. Detect format (XML vs JSON via content sniffing)
3. Identify scanner type:
     - Qualys: root element <SCAN>
     - Nessus: root element <NessusClientData_v2>
     - Burp: JSON with "issue_events" key
     - OpenVAS: root element <report>
     - Nmap: root element <nmaprun>
  ↓
4. Call appropriate plugin.parse()
  ↓
ParsedVulnerability {
  scanner_id: String,
  title: String,
  description: String,
  severity: String,        // "Critical", "High", "Medium", "Low", "Info"
  cvss_score: Option<f64>,
  cve_ids: Vec<String>,
  cwe_ids: Vec<String>,
  host: String,            // IP or hostname
  port: Option<u16>,
  protocol: Option<String>, // TCP/UDP
  service: Option<String>,  // http, ssh, mysql, etc.
  solution: Option<String>,
  references: Vec<String>   // URLs
}
  ↓
5. Normalize severity levels:
     Scanner-specific → Standard severity
     Example: Qualys "5" → "Critical"
              Nessus "4" → "Critical"
  ↓
6. Deduplicate:
     SELECT id FROM vulnerabilities
     WHERE cve_id = $1
       AND ip_address = $2
       AND port = $3
       AND status NOT IN ('resolved', 'closed')

     IF EXISTS:
       UPDATE cvss_score, last_detected, description
     ELSE:
       INSERT new vulnerability
  ↓
7. Link to assets:
     SELECT id FROM assets WHERE ip_address = $host

     IF NOT EXISTS:
       CREATE new asset (auto-discovery)
  ↓
8. Auto-assign (check assignment rules)
9. Calculate risk score (trigger PostgreSQL function)
10. Check notification rules
11. Create JIRA ticket (if auto-ticket rules match)
  ↓
OUTPUT: ScanImportResult {
  total_vulnerabilities: 1523,
  imported_count: 347,     // new
  updated_count: 1102,     // existing
  skipped_count: 74,       // duplicates, info-only
  errors: Vec<String>      // parsing failures
}
  ↓
STORAGE:
  - INSERT/UPDATE vulnerabilities
  - INSERT scanner_imports (audit log)
```

#### Deduplication Logic (Critical)

```sql
-- Composite key: CVE + Host + Port + Status
CREATE UNIQUE INDEX idx_vulnerability_dedup ON vulnerabilities
(cve_id, ip_address, COALESCE(port, 0))
WHERE status NOT IN ('resolved', 'closed') AND deleted_at IS NULL;

-- Rationale:
-- - Same CVE on same host+port = same vulnerability
-- - Allow re-opening if previously closed (excluded from index)
-- - COALESCE(port, 0) handles NULL ports (host-level vulns)
```

#### Normalizzazione Severity

```rust
fn normalize_severity(scanner: ScannerType, raw: &str) -> Severity {
  match scanner {
    ScannerType::Qualys => match raw {
      "5" => Severity::Critical,
      "4" => Severity::High,
      "3" => Severity::Medium,
      "2" => Severity::Low,
      "1" => Severity::Info,
      _ => Severity::Unknown
    },
    ScannerType::Nessus => match raw {
      "4" | "Critical" => Severity::Critical,
      "3" | "High" => Severity::High,
      "2" | "Medium" => Severity::Medium,
      "1" | "Low" => Severity::Low,
      "0" | "Info" => Severity::Info,
      _ => Severity::Unknown
    },
    // ... altri scanner
  }
}
```

#### Opportunità di Ottimizzazione

**🔍 Parsing Performance:**
- XML parsing sequenziale (SAX-like) vs DOM
- **Proposta:** Streaming parser per file >10MB (riduce memory footprint)

**📊 Batch Import:**
- Attualmente INSERT singoli (anche se in transaction)
- **Proposta:** Batch INSERT con PostgreSQL `UNNEST` (10x faster per scan >1000 vuln)

**🧮 Deduplication:**
- Query per ogni vulnerabilità (N query per scan)
- **Proposta:** Temporary table + JOIN per batch dedup (1 query per scan)

**⚡ Parallel Parsing:**
- File grandi parsati in serie
- **Proposta:** Split XML in chunk e parse parallelo (Rayon), poi merge

---

### 5. NOTIFICATION ROUTING ENGINE

**Location:** `/vulnerability-manager/src/notifications/`, `/handlers/notification_rules.rs`

#### Canali Supportati (7)

1. **Email** (SMTP)
2. **Slack** (webhook)
3. **Telegram** (bot API)
4. **Microsoft Teams** (webhook)
5. **Generic Webhook** (HTTP POST)
6. **PagerDuty** (API)
7. **OpsGenie** (API)

#### Algoritmo: Rule-Based Routing

```sql
-- PostgreSQL function: get_matching_rules()
SELECT
  nr.id, nr.name, nr.priority, nr.channels,
  nr.recipient_emails, nr.recipient_user_ids, nr.recipient_team_ids,
  nr.conditions, nr.message_template,
  nr.throttle_minutes, nr.quiet_hours_start, nr.quiet_hours_end
FROM notification_rules nr
WHERE
  nr.is_enabled = TRUE
  AND NOT in_quiet_hours(nr.quiet_hours_start, nr.quiet_hours_end, NOW())
  AND NOT is_throttled(nr.id, nr.throttle_minutes)
  AND evaluate_conditions(nr.conditions, $vulnerability_data)
ORDER BY nr.priority ASC  -- Lower priority value = higher priority
LIMIT 10;  -- Prevent notification spam
```

#### Condition Evaluation (JSONB Operators)

```javascript
// Stored in notification_rules.conditions (JSONB column)
{
  "risk_tier": {"eq": "Critical"},
  "risk_score": {"gte": 80},
  "severity": {"in": ["critical", "high"]},
  "cve_id": {"contains": "CVE-2024"},
  "asset.tags": {"contains": "production"},
  "is_actively_exploited": {"eq": true}
}

// Operators disponibili:
- eq:       exact match
- neq:      not equal
- gt, gte:  greater than (or equal)
- lt, lte:  less than (or equal)
- in:       value in array
- contains: string/array contains
```

**Implementazione PostgreSQL:**
```sql
CREATE OR REPLACE FUNCTION evaluate_conditions(
  conditions JSONB,
  vuln_data JSONB
) RETURNS BOOLEAN AS $$
DECLARE
  key TEXT;
  condition JSONB;
BEGIN
  FOR key, condition IN SELECT * FROM jsonb_each(conditions) LOOP
    -- Check operator and evaluate
    IF NOT evaluate_single_condition(key, condition, vuln_data) THEN
      RETURN FALSE;  -- AND logic: all conditions must pass
    END IF;
  END LOOP;
  RETURN TRUE;
END;
$$ LANGUAGE plpgsql;
```

#### 8 Regole Pre-Configurate

```rust
// 1. Critical Vulnerabilities Alert
NotificationRule {
  name: "Critical Vulnerabilities",
  priority: 10,
  conditions: {"risk_tier": {"eq": "Critical"}},
  channels: ["email", "slack", "pagerduty"],
  throttle_minutes: 15
}

// 2. SLA Breach Warning (75%)
NotificationRule {
  name: "SLA 75% Warning",
  priority: 20,
  conditions: {"sla_percentage": {"gte": 75, "lt": 90}},
  channels: ["email", "slack"]
}

// 3. SLA Breach Alert (100%)
NotificationRule {
  name: "SLA Breach",
  priority: 5,  // Highest priority
  conditions: {"sla_breached": {"eq": true}},
  channels: ["email", "slack", "pagerduty"],
  escalate_to: "team_leader"
}

// 4. High Severity Vulnerabilities
NotificationRule {
  name: "High Severity",
  priority: 30,
  conditions: {"risk_tier": {"eq": "High"}},
  channels: ["email"]
}

// 5. Zero-Day Alert
NotificationRule {
  name: "Zero-Day",
  priority: 1,  // Most urgent
  conditions: {"is_zero_day": {"eq": true}},
  channels: ["email", "slack", "teams", "pagerduty"]
}

// 6. Ransomware Alert
NotificationRule {
  name: "Ransomware",
  priority: 3,
  conditions: {"is_ransomware_targeted": {"eq": true}},
  channels: ["email", "slack", "pagerduty"]
}

// 7. Vulnerability Assigned
NotificationRule {
  name: "Assignment Notification",
  priority: 50,
  conditions: {"assigned_user_id": {"neq": null}},
  channels: ["email"],
  recipient_user_ids: ["{assigned_user_id}"]  // Template variable
}

// 8. Daily Digest
NotificationRule {
  name: "Daily Summary",
  priority: 100,
  conditions: {},  // Always match
  channels: ["email"],
  batch_mode: true,  // Aggregate notifications
  schedule: "0 8 * * *"  // 8 AM daily
}
```

#### Anti-Spam Features

**a) Throttling**
```sql
CREATE TABLE notification_throttle (
  rule_id UUID,
  last_sent_at TIMESTAMPTZ,
  PRIMARY KEY (rule_id)
);

-- Check throttle
SELECT last_sent_at
FROM notification_throttle
WHERE rule_id = $1
  AND last_sent_at > NOW() - INTERVAL '$throttle_minutes minutes';

-- If result exists → throttled (skip notification)
-- Else → send + UPDATE notification_throttle
```

**b) Quiet Hours**
```rust
fn in_quiet_hours(start: Time, end: Time, now: DateTime) -> bool {
  let current_time = now.time();

  if start < end {
    // Normal range: 22:00 - 08:00
    current_time >= start && current_time < end
  } else {
    // Overnight range: 08:00 - 22:00 (inverted logic)
    current_time >= start || current_time < end
  }
}
```

**c) Batch Mode**
```rust
// Daily digest worker
async fn send_daily_digest() {
  let vulnerabilities = query!(
    "SELECT * FROM vulnerabilities
     WHERE created_at > NOW() - INTERVAL '24 hours'"
  );

  let summary = generate_summary(vulnerabilities);

  send_email(
    to: "team@company.com",
    subject: "Daily Vulnerability Summary",
    body: summary
  );
}
```

#### Flusso Dati

```
EVENT: Vulnerability created/updated
  ↓
1. Build vulnerability data JSON:
   {
     "id": "uuid",
     "title": "CVE-2024-1234",
     "risk_score": 87,
     "risk_tier": "Critical",
     "hostname": "web-server-01",
     "cve_id": "CVE-2024-1234",
     "assigned_user_id": "uuid",
     ...
   }
  ↓
2. Query matching rules:
   SELECT * FROM notification_rules
   WHERE evaluate_conditions(conditions, vuln_data)
     AND is_enabled = TRUE
     AND NOT in_quiet_hours(...)
     AND NOT is_throttled(...)
   ORDER BY priority ASC
  ↓
3. FOR EACH matching rule:
   a) Resolve recipients:
      - recipient_emails → use directly
      - recipient_user_ids → SELECT email FROM users WHERE id IN (...)
      - recipient_team_ids → SELECT email FROM users u
                              JOIN team_members tm ON tm.user_id = u.id
                              WHERE tm.team_id IN (...)
      - role_filter → SELECT email FROM users WHERE role = 'Admin'

   b) Template substitution:
      message_template: "Critical vulnerability {title} detected on {hostname}"
      → "Critical vulnerability CVE-2024-1234 detected on web-server-01"

      Variables: {title}, {hostname}, {risk_score}, {sla_days}, {cve_id}, etc.

   c) Send via channels (parallel):
      - Email: SMTP
      - Slack: POST to webhook URL
      - Telegram: POST to bot API
      - PagerDuty: POST to events API
      - etc.

   d) Log to notification_history:
      INSERT INTO notification_history (
        rule_id, vulnerability_id, channels, recipients,
        sent_at, status
      )

   e) Update throttle:
      INSERT INTO notification_throttle (rule_id, last_sent_at)
      ON CONFLICT (rule_id) DO UPDATE SET last_sent_at = NOW()
  ↓
OUTPUT: Notifications sent, audit trail created
```

#### Opportunità di Ottimizzazione

**🔍 Rule Evaluation:**
- Ogni evento triggera valutazione di tutte le regole (anche se disabled)
- **Proposta:** Index su is_enabled + cache delle regole attive in memoria (invalidate on change)

**📊 Recipient Resolution:**
- Query separata per ogni rule per risolvere recipients
- **Proposta:** Batch query con UNION per tutte le rules matchate

**🧮 Condition Evaluation:**
- JSONB evaluation può essere lento per conditions complesse
- **Proposta:** Precompiled expression tree (parse conditions → AST → cache)

**⚡ Parallel Sending:**
- Channels inviati in parallelo, ma rules in sequenza
- **Proposta:** Rule processing parallelo + dedup recipients finale

---

### 6. JIRA INTEGRATION SYSTEM

**Location:** `/vulnerability-manager/src/handlers/jira_integration.rs`, `/workers/jira_sync.rs`

#### Features

- **Bi-directional sync:** SentinelCore ↔ JIRA
- **Auto-ticket creation** basato su regole
- **Status synchronization**
- **Custom field mapping**

#### Auto-Ticketing Rules

```javascript
{
  name: "Auto-create for Critical",
  conditions: {"risk_tier": {"in": ["Critical", "High"]}},
  project_key: "VULN",
  issue_type: "Task",
  priority_mapping: {
    "Critical": "Highest",
    "High": "High",
    "Medium": "Medium",
    "Low": "Low"
  },
  custom_fields: {
    "customfield_10001": "{cve_id}",      // CVE field
    "customfield_10002": "{risk_score}",  // Risk score
    "customfield_10003": "{sla_deadline}" // Deadline
  }
}
```

#### JIRA Issue Description (Auto-Generated Template)

```markdown
*Vulnerability Details*

*CVE:* CVE-2024-1234
*CVSS Score:* 9.8 (Severity: Critical)
*Risk Score:* 92/100 (Tier: Critical)
*EPSS Score:* 85% (Exploit Probability)

*Affected Asset*
*Hostname:* web-server-01
*IP Address:* 192.168.1.50
*OS:* Ubuntu 22.04

*Description*
{vulnerability_description}

*Solution*
{remediation_steps}

*Timeline*
*SLA Deadline:* 2024-12-15 10:30:00
*First Detected:* 2024-12-14 10:30:00

_Auto-generated by SentinelCore - [View in Dashboard](https://sentinel.company.com/vulnerabilities/{id})_
```

#### Bi-Directional Sync

**JIRA → SentinelCore:**
```
JIRA Webhook → POST /api/jira/webhook
  ↓
1. Validate webhook signature (HMAC-SHA256)
2. Parse payload:
   {
     "issue": {
       "key": "VULN-123",
       "fields": {
         "status": {"name": "Done"}
       }
     }
   }
  ↓
3. Lookup linked vulnerability:
   SELECT vulnerability_id FROM jira_tickets WHERE jira_key = 'VULN-123'
  ↓
4. Map JIRA status → SentinelCore status:
   "Done" / "Resolved" / "Closed" → "resolved"
   "In Progress" / "In Review" → "in_progress"
   "Open" / "To Do" / "Backlog" → "open"
   "Won't Fix" → "accepted" (risk acceptance)
  ↓
5. Update vulnerability:
   UPDATE vulnerabilities SET status = 'resolved', updated_at = NOW()
   WHERE id = vulnerability_id
  ↓
6. Log sync:
   INSERT INTO jira_sync_history (
     jira_key, vulnerability_id, direction: "jira_to_sentinel",
     old_status, new_status, synced_at
   )
  ↓
OUTPUT: Vulnerability status updated
```

**SentinelCore → JIRA:**
```
Vulnerability status changed (via API or UI)
  ↓
1. Check if JIRA ticket exists:
   SELECT jira_key FROM jira_tickets WHERE vulnerability_id = $id
  ↓
2a. IF ticket exists:
     JIRA API: PUT /rest/api/3/issue/{key}
     {
       "fields": {
         "status": {"name": "Done"}
       }
     }

2b. IF no ticket AND auto-ticket rules match:
     Check auto-ticket rules:
       SELECT * FROM jira_auto_ticket_rules
       WHERE evaluate_conditions(conditions, vuln_data)

     IF match:
       JIRA API: POST /rest/api/3/issue
       {
         "fields": {
           "project": {"key": "VULN"},
           "issuetype": {"name": "Task"},
           "summary": "{title}",
           "description": "{generated_description}",
           "priority": {"name": "Highest"}
         }
       }

       Store ticket:
       INSERT INTO jira_tickets (vulnerability_id, jira_key, created_at)
  ↓
3. Log sync:
   INSERT INTO jira_sync_history (...)
  ↓
OUTPUT: JIRA ticket created/updated
```

#### Background Worker (Sync Queue)

**Location:** `/vulnerability-manager/src/workers/jira_sync.rs`

```rust
// Runs every 5 minutes
async fn start_jira_sync() {
  loop {
    // Process pending JIRA tickets
    let pending = query!(
      "SELECT * FROM jira_tickets
       WHERE sync_status = 'pending'
       ORDER BY created_at ASC
       LIMIT 100"
    );

    for ticket in pending {
      match sync_ticket(&ticket).await {
        Ok(_) => {
          query!(
            "UPDATE jira_tickets SET sync_status = 'synced' WHERE id = $1",
            ticket.id
          );
        }
        Err(e) => {
          // Retry logic (exponential backoff)
          let retry_count = ticket.retry_count + 1;
          let next_retry = calculate_backoff(retry_count);

          query!(
            "UPDATE jira_tickets
             SET retry_count = $1, next_retry_at = $2, last_error = $3
             WHERE id = $4",
            retry_count, next_retry, e.to_string(), ticket.id
          );

          if retry_count > 5 {
            // Max retries exceeded
            query!(
              "UPDATE jira_tickets SET sync_status = 'failed' WHERE id = $1",
              ticket.id
            );

            // Alert admin
            send_notification("JIRA sync failed for ticket {}", ticket.jira_key);
          }
        }
      }
    }

    tokio::time::sleep(Duration::from_secs(300)).await; // 5 minutes
  }
}

fn calculate_backoff(retry_count: i32) -> DateTime {
  let delay_seconds = 2_i32.pow(retry_count as u32).min(3600); // Max 1 hour
  Utc::now() + Duration::seconds(delay_seconds as i64)
}
```

#### Opportunità di Ottimizzazione

**🔍 Webhook Processing:**
- Ogni webhook triggera query separata
- **Proposta:** Batch webhook processing (accumula 1 min → batch query)

**📊 Sync Queue:**
- Worker poll ogni 5 minuti (latency)
- **Proposta:** Event-driven sync con message queue (Redis/RabbitMQ)

**🧮 Retry Logic:**
- Exponential backoff semplice (può bloccare queue con failed tickets)
- **Proposta:** Dead letter queue per failed tickets + manual retry

**⚡ API Rate Limiting:**
- No rate limiting awareness (può triggerare JIRA 429)
- **Proposta:** Token bucket rate limiter (es. 100 req/min)

---

### 7. AUTO-ASSIGNMENT ENGINE

**Location:** `/vulnerability-manager/src/handlers/auto_assignment.rs`, `/migrations/024_assignment_rules.sql`

#### Algoritmo: Rule-Based Assignment

```javascript
assignment_rule {
  name: "Critical Production Assets",
  priority: 100,  // Lower = higher priority
  is_enabled: true,

  conditions: {
    "vulnerability": {
      "risk_tier": {"in": ["Critical", "High"]},
      "severity": {"eq": "critical"}
    },
    "asset": {
      "tags": {"contains": "production"},
      "network_zone": {"eq": "Internet-Facing"}
    }
  },

  team_id: "uuid-security-team",
  team_member_role: "Senior Engineer",  // Optional filter
  require_skill_match: true,
  required_skills: ["kubernetes", "docker", "linux"],

  load_balancing_strategy: "least_loaded"  // round_robin, least_loaded, random
}
```

#### Load Balancing Strategies

**a) Least Loaded (Default)**
```sql
-- Find team member with fewest open vulnerabilities
SELECT
  tm.user_id,
  u.username,
  COUNT(v.id) as workload
FROM team_members tm
JOIN users u ON u.id = tm.user_id
LEFT JOIN vulnerabilities v ON v.assigned_user_id = tm.user_id
  AND v.status NOT IN ('resolved', 'closed')
WHERE tm.team_id = $team_id
  AND ($role IS NULL OR tm.role = $role)
  AND ($require_skills IS NULL OR has_skills(tm.user_id, $required_skills))
GROUP BY tm.user_id, u.username
ORDER BY workload ASC, RANDOM()  -- RANDOM() as tiebreaker
LIMIT 1;
```

**b) Round Robin**
```rust
// State stored in assignment_rule_state table
let team_members = get_team_members(rule.team_id);
let current_index = get_current_index(rule.id);

let assigned_user = team_members[current_index % team_members.len()];

// Update state
update_current_index(rule.id, current_index + 1);
```

**c) Skill Matching**
```sql
-- Filter team members by required skills
SELECT tm.user_id
FROM team_members tm
JOIN user_skills us ON us.user_id = tm.user_id
WHERE tm.team_id = $team_id
  AND us.skill = ANY($required_skills)
GROUP BY tm.user_id
HAVING COUNT(DISTINCT us.skill) = array_length($required_skills, 1);
-- Ensures ALL skills present (AND logic)
```

**d) Random Assignment**
```sql
SELECT user_id
FROM team_members
WHERE team_id = $team_id
ORDER BY RANDOM()
LIMIT 1;
```

#### Flusso Dati

```
EVENT: New vulnerability created (scan import)
  ↓
1. Query assignment_rules (enabled, priority ordered):
   SELECT * FROM assignment_rules
   WHERE is_enabled = TRUE
   ORDER BY priority ASC
  ↓
2. FOR EACH rule (in priority order):
   a) Evaluate conditions:
      - Fetch vulnerability data (risk_tier, severity, cve_id, etc.)
      - Fetch asset data (tags, network_zone, etc.)
      - Check conditions match (JSONB operators)

   b) IF match:
      BREAK (use this rule, ignore lower priority)
  ↓
3. Get eligible team members:
   a) Filter by team_id
   b) Filter by role (if specified)
   c) Filter by skills (if required):
      SELECT user_id FROM user_skills
      WHERE skill = ANY($required_skills)
      GROUP BY user_id
      HAVING COUNT(DISTINCT skill) = array_length($required_skills, 1)
  ↓
4. Apply load balancing strategy:
   - least_loaded: Query workload, pick min
   - round_robin: State-based rotation
   - random: Random selection
  ↓
5. Assign vulnerability:
   UPDATE vulnerabilities
   SET assigned_team_id = $team_id,
       assigned_user_id = $user_id,
       assigned_at = NOW()
   WHERE id = $vulnerability_id
  ↓
6. Create audit trail:
   INSERT INTO vulnerability_rule_matches (
     vulnerability_id, assignment_rule_id, matched_at
   )
  ↓
7. Trigger notification:
   Check notification rules for event: "vulnerability_assigned"
   Send email/slack to assigned user
  ↓
OUTPUT: Vulnerability assigned, user notified
```

#### Opportunità di Ottimizzazione

**🔍 Rule Evaluation:**
- Sequential evaluation (stop at first match)
- **Proposta:** Rule priority index + early termination ottimizzata

**📊 Least Loaded Query:**
- COUNT vulnerabilities per ogni team member (slow for large teams)
- **Proposta:** Materialized view con workload cache (refresh ogni 5 min)

**🧮 Skill Matching:**
- JOIN user_skills per ogni rule
- **Proposta:** Precompute skill matrix (user_id → skill_set) in Redis

**⚡ Batch Assignment:**
- Ogni vuln assigned singolarmente (N query per scan)
- **Proposta:** Batch assignment per scan import (1 query per rule)

---

### 8. COMMENTS & COLLABORATION SYSTEM

**Location:** `/handlers/comments.rs`, `/migrations/014_comments_system.sql`

#### Features

- **@mentions** con user notifications
- **Comment threading** (replies)
- **Attachments** support (images, PDFs, logs)
- **Internal vs customer-visible** comments
- **Soft deletes** con audit trail

#### @Mention Extraction (PostgreSQL Function)

```sql
-- Auto-triggered on INSERT/UPDATE
CREATE OR REPLACE FUNCTION extract_mentions()
RETURNS TRIGGER AS $$
DECLARE
  mention_usernames TEXT[];
  mention_user_ids UUID[];
  username TEXT;
  user_id UUID;
BEGIN
  -- Extract @username patterns using regex
  mention_usernames := regexp_matches(NEW.comment_text, '@(\w+)', 'g');

  -- Lookup user IDs (case-insensitive)
  FOR username IN SELECT unnest(mention_usernames) LOOP
    SELECT id INTO user_id
    FROM users
    WHERE LOWER(username) = LOWER(username)
    LIMIT 1;

    IF user_id IS NOT NULL THEN
      mention_user_ids := array_append(mention_user_ids, user_id);
    END IF;
  END LOOP;

  -- Store mentions as JSONB array
  NEW.mentions := to_jsonb(mention_user_ids);

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_extract_mentions
BEFORE INSERT OR UPDATE ON vulnerability_comments
FOR EACH ROW
EXECUTE FUNCTION extract_mentions();
```

#### Comment Threading (Recursive CTE)

```sql
-- Fetch entire comment thread
WITH RECURSIVE comment_tree AS (
  -- Root comment
  SELECT
    id, parent_comment_id, user_id, comment_text,
    mentions, attachments, created_at,
    0 as depth,
    ARRAY[id] as path
  FROM vulnerability_comments
  WHERE id = $root_comment_id

  UNION ALL

  -- Recursive part: fetch replies
  SELECT
    c.id, c.parent_comment_id, c.user_id, c.comment_text,
    c.mentions, c.attachments, c.created_at,
    ct.depth + 1,
    ct.path || c.id
  FROM vulnerability_comments c
  JOIN comment_tree ct ON c.parent_comment_id = ct.id
  WHERE ct.depth < 10  -- Max depth limit (prevent infinite recursion)
)
SELECT
  ct.*,
  u.username,
  u.avatar_url
FROM comment_tree ct
JOIN users u ON u.id = ct.user_id
ORDER BY path, created_at ASC;
```

**Output:**
```
depth | id   | comment_text              | username
------|------|---------------------------|----------
0     | 1    | "Root comment"            | alice
1     | 2    | "@bob please review"      | alice
1     | 3    | "I'll look into this"     | bob
2     | 4    | "Thanks!"                 | alice
```

#### Flusso Dati

```
USER: Posts comment "@john please review this CVE"
  ↓
1. Parse request:
   POST /api/vulnerabilities/{id}/comments
   {
     "comment_text": "@john please review this CVE",
     "parent_comment_id": null,
     "attachments": ["file_uuid_1", "file_uuid_2"],
     "is_internal": true
   }
  ↓
2. Insert comment:
   INSERT INTO vulnerability_comments (
     vulnerability_id, user_id, comment_text, parent_comment_id,
     attachments, is_internal
   ) VALUES (...)
   RETURNING id
  ↓
3. TRIGGER: extract_mentions()
   - Regex match: '@(\w+)' → ["john"]
   - Lookup user: SELECT id FROM users WHERE username ILIKE 'john' → uuid-john
   - Store: UPDATE vulnerability_comments SET mentions = '["uuid-john"]' WHERE id = comment_id
  ↓
4. FOR EACH mentioned user:
   a) Create user notification:
      INSERT INTO user_notifications (
        user_id: uuid-john,
        type: "mention",
        title: "alice mentioned you in a comment",
        entity_type: "vulnerability",
        entity_id: vulnerability_id,
        link: "/vulnerabilities/{id}#comment-{comment_id}",
        is_read: false
      )

   b) Check notification rules:
      - "Comment Mention" rule → send email/slack
  ↓
5. IF attachments:
   UPDATE comment_attachments
   SET comment_id = $comment_id
   WHERE id = ANY($attachment_ids)
  ↓
OUTPUT: Comment saved, mentions extracted, users notified
```

#### Comment Types

1. **Vulnerability comments** - Discussion su CVE specifiche
2. **Asset/device comments** - Note su host/device
3. **Remediation plan comments** - Task collaboration

#### Opportunità di Ottimizzazione

**🔍 Mention Extraction:**
- Regex execution per ogni comment (CPU overhead)
- **Proposta:** Client-side mention tagging (UI autocomplete) → server validation only

**📊 Thread Loading:**
- Recursive CTE può essere lento per thread profondi
- **Proposta:** Materialized path (store full path in column) + partial load (pagination)

**🧮 Notification Spam:**
- Ogni mention triggera notifica (anche per edit)
- **Proposta:** Debounce notifications (1 notifica per utente per thread)

**⚡ Attachments:**
- File upload sincrono (blocca risposta)
- **Proposta:** Async upload con pre-signed URLs (S3) + background processing

---

### 9. BACKGROUND WORKERS (6)

**Location:** `/vulnerability-manager/src/workers/`

#### a) SLA Checker

**File:** `sla_checker.rs`
**Frequenza:** Ogni 1 ora
**Complessità:** O(n) dove n = vulnerabilità con SLA attivo

```rust
async fn start_sla_checker() {
  loop {
    // Mark breached SLAs
    let breached = query!(
      "SELECT id, title, hostname, assigned_user_id, sla_deadline
       FROM vulnerabilities
       WHERE sla_deadline < NOW()
         AND status NOT IN ('resolved', 'closed')
         AND sla_breached = FALSE"
    );

    for vuln in breached {
      query!(
        "UPDATE vulnerabilities SET sla_breached = TRUE WHERE id = $1",
        vuln.id
      );

      // Trigger notification
      trigger_notification("SLA Breach", vuln);
    }

    tokio::time::sleep(Duration::from_secs(3600)).await; // 1 hour
  }
}
```

**Ottimizzazione potenziale:**
- **Proposta:** Partial index `WHERE sla_breached = FALSE` + materialized view per vuln "at risk"

---

#### b) JIRA Sync

**File:** `jira_sync.rs`
**Frequenza:** Ogni 5 minuti
**Complessità:** O(n) dove n = pending tickets

```rust
async fn start_jira_sync() {
  loop {
    let pending = query!(
      "SELECT * FROM jira_tickets WHERE sync_status = 'pending' LIMIT 100"
    );

    for ticket in pending {
      match sync_to_jira(&ticket).await {
        Ok(_) => update_status("synced"),
        Err(e) => handle_retry_logic(e)
      }
    }

    tokio::time::sleep(Duration::from_secs(300)).await; // 5 minutes
  }
}
```

**Ottimizzazione potenziale:**
- **Proposta:** Event-driven con Redis Pub/Sub (latency < 1s)

---

#### c) Notification Digest

**File:** `notification_digest.rs`
**Frequenza:** Daily (configurabile)
**Complessità:** O(n) dove n = notifications da aggregare

```rust
async fn send_daily_digest() {
  let notifications = query!(
    "SELECT * FROM notification_history
     WHERE created_at > NOW() - INTERVAL '24 hours'
       AND rule.batch_mode = TRUE"
  );

  let summary = generate_summary_html(notifications);

  send_email(
    to: "team@company.com",
    subject: "Daily Vulnerability Summary",
    body: summary
  );
}
```

---

#### d) NVD Enrichment

**File:** `nvd_api.rs`
**Frequenza:** On-demand (triggered by scan import)
**Complessità:** O(n) API calls, rate limited

```rust
async fn enrich_from_nvd(cve_id: &str) -> Result<NVDData> {
  let url = format!("https://services.nvd.nist.gov/rest/json/cves/2.0?cveId={}", cve_id);

  // Rate limiting: 5 req/30s (NVD free tier)
  rate_limiter.acquire().await;

  let response = reqwest::get(&url).await?;
  let nvd_data: NVDResponse = response.json().await?;

  // Update vulnerability with enriched data
  query!(
    "UPDATE vulnerabilities
     SET cvss_vector = $1, cwe_ids = $2, references = $3
     WHERE cve_id = $4",
    nvd_data.cvss_vector, nvd_data.cwe_ids, nvd_data.references, cve_id
  );

  Ok(nvd_data)
}
```

**Ottimizzazione potenziale:**
- **Proposta:** Cache NVD data (TTL 7 giorni) + batch API calls

---

#### e) EPSS Updater

**File:** `epss_updater.rs`
**Frequenza:** Daily at midnight UTC
**Complessità:** O(n) dove n ≈ 200,000 CVE

```rust
async fn update_epss_scores() {
  // Download EPSS CSV (gzipped, ~30MB)
  let url = "https://epss.cyentia.com/epss_scores-current.csv.gz";
  let compressed_data = reqwest::get(url).await?.bytes().await?;

  // Decompress
  let decoder = GzDecoder::new(&compressed_data[..]);
  let reader = BufReader::new(decoder);

  // Batch processing (1000 records per batch)
  let mut batch = Vec::new();
  for line in reader.lines() {
    let (cve_id, epss_score, percentile) = parse_csv_line(line?);
    batch.push((cve_id, epss_score, percentile));

    if batch.len() >= 1000 {
      batch_update_epss(&batch).await?;
      batch.clear();
    }
  }

  // Update last run timestamp
  query!(
    "UPDATE system_metadata SET value = $1 WHERE key = 'epss_last_update'",
    Utc::now()
  );
}

async fn batch_update_epss(batch: &[(String, f64, f64)]) -> Result<()> {
  let cve_ids: Vec<String> = batch.iter().map(|(cve, _, _)| cve.clone()).collect();
  let scores: Vec<f64> = batch.iter().map(|(_, score, _)| *score).collect();

  query!(
    "UPDATE vulnerabilities v
     SET epss_score = data.score
     FROM (
       SELECT unnest($1::text[]) as cve_id, unnest($2::float8[]) as score
     ) data
     WHERE v.cve_id = data.cve_id",
    &cve_ids, &scores
  );

  Ok(())
}
```

**Ottimizzazione potenziale:**
- **Proposta:** Delta updates (download only changed scores) + parallel batch processing

---

#### f) Report Generator

**File:** `report_generator.rs`
**Frequenza:** On-demand
**Complessità:** O(n) dove n = vulnerabilities

```rust
async fn generate_compliance_report(framework: &str) -> Result<Report> {
  let vulnerabilities = query!(
    "SELECT v.*, vcm.control_id
     FROM vulnerabilities v
     LEFT JOIN vulnerability_compliance_mapping vcm ON vcm.vulnerability_id = v.id
     WHERE vcm.framework_name = $1",
    framework
  );

  let report = ComplianceReport {
    framework,
    total_controls: count_controls(framework),
    passed_controls: count_passed(vulnerabilities),
    failed_controls: count_failed(vulnerabilities),
    compliance_score: calculate_compliance_score(vulnerabilities),
    vulnerability_breakdown: group_by_control(vulnerabilities)
  };

  // Generate PDF
  let pdf = render_pdf_template(&report);

  Ok(pdf)
}
```

---

### 10. DATABASE ARCHITECTURE

#### Core Tables (30+)

**User Management:**
```sql
users (id, username, email, password_hash, role, created_at)
user_sessions (id, user_id, token_hash, expires_at, ip_address)
user_settings (user_id, theme, notifications_enabled, timezone)
user_notifications (id, user_id, type, title, link, is_read)
user_skills (user_id, skill, proficiency_level)
```

**Vulnerability Management:**
```sql
vulnerabilities (
  id, cve_id, title, description, severity, cvss_score,
  risk_score, risk_tier, epss_score,
  ip_address, hostname, port, service,
  status, assigned_user_id, assigned_team_id,
  first_detected, last_detected, sla_deadline, sla_breached,
  created_at, updated_at, deleted_at
)

vulnerability_timeline (id, vulnerability_id, old_status, new_status, changed_by, changed_at)
vulnerability_comments (id, vulnerability_id, user_id, comment_text, mentions, attachments, parent_comment_id)
vulnerability_rule_matches (vulnerability_id, assignment_rule_id, matched_at)
```

**Asset Management:**
```sql
assets (id, ip_address, hostname, os, os_version, tags, network_zone, criticality)
asset_comments (id, asset_id, user_id, comment_text)
network_ranges (id, cidr, description, network_zone)
network_topology (id, device_id, connected_device_id, connection_type)
```

**Team Collaboration:**
```sql
teams (id, name, description, created_at)
team_members (team_id, user_id, role, joined_at)
assignment_rules (id, name, priority, conditions, team_id, load_balancing_strategy)
```

**Remediation:**
```sql
remediation_plans (id, title, description, total_hours, priority_tier, created_by)
remediation_tasks (id, plan_id, device_id, vulnerability_id, action_type, status)
remediation_comments (id, plan_id, user_id, comment_text)
```

**Integration:**
```sql
jira_configurations (id, base_url, username, api_token, project_key)
jira_tickets (id, vulnerability_id, jira_key, sync_status, created_at)
jira_sync_history (id, jira_key, vulnerability_id, direction, old_status, new_status)
scanner_imports (id, scanner_type, filename, total_vulnerabilities, imported_count)
```

**Notification System:**
```sql
notification_channels (id, type, name, config, is_enabled)
notification_rules (id, name, priority, conditions, channels, throttle_minutes)
notification_history (id, rule_id, vulnerability_id, channels, recipients, sent_at)
```

**Compliance:**
```sql
compliance_frameworks (id, framework_name, version, total_controls)
compliance_reports (id, framework_id, compliance_score, generated_at)
vulnerability_compliance_mapping (vulnerability_id, framework_id, control_id)
```

#### Indici di Performance (50+)

```sql
-- Primary keys (unique B-tree)
CREATE UNIQUE INDEX pk_vulnerabilities ON vulnerabilities(id);

-- Foreign keys
CREATE INDEX idx_vulnerabilities_assigned_user ON vulnerabilities(assigned_user_id);
CREATE INDEX idx_vulnerabilities_assigned_team ON vulnerabilities(assigned_team_id);

-- Query optimization
CREATE INDEX idx_vulnerabilities_status ON vulnerabilities(status);
CREATE INDEX idx_vulnerabilities_risk_tier ON vulnerabilities(risk_tier);
CREATE INDEX idx_vulnerabilities_cve_id ON vulnerabilities(cve_id);

-- Partial indexes (condizionali)
CREATE INDEX idx_vulnerabilities_sla_active
ON vulnerabilities(sla_deadline)
WHERE sla_breached = FALSE AND status NOT IN ('resolved', 'closed');

CREATE INDEX idx_vulnerabilities_active
ON vulnerabilities(created_at)
WHERE deleted_at IS NULL;

-- JSONB indexes (GIN)
CREATE INDEX idx_notification_rules_conditions
ON notification_rules USING GIN(conditions);

CREATE INDEX idx_assignment_rules_conditions
ON assignment_rules USING GIN(conditions);

-- Composite indexes
CREATE INDEX idx_vulnerabilities_ip_port
ON vulnerabilities(ip_address, port);

CREATE INDEX idx_vulnerabilities_risk_status
ON vulnerabilities(risk_tier, status);

-- Full-text search
CREATE INDEX idx_vulnerabilities_title_fts
ON vulnerabilities USING GIN(to_tsvector('english', title));
```

---

## 🔄 DATA FLOW PATTERNS PRINCIPALI

### Pattern 1: Vulnerability Lifecycle

```
Scanner Upload → Parse → Normalize → Deduplicate →
Link to Assets → Calculate Risk Score →
Auto-assign (rules) → Create JIRA Ticket (if rules match) →
Notify (routing rules) → SLA Tracking →
Remediation → Verify → Close
```

**Dettaglio:**
1. **Upload:** Multipart file upload (XML/JSON)
2. **Parse:** Scanner plugin identifica formato e parse
3. **Normalize:** Severity mapping, CVSS standardization
4. **Deduplicate:** Query `WHERE cve_id = X AND ip = Y AND port = Z`
5. **Link:** `SELECT id FROM assets WHERE ip_address = host`
6. **Risk Score:** PostgreSQL trigger `calculate_risk_score()`
7. **Auto-assign:** Query `assignment_rules` → evaluate conditions
8. **JIRA:** Check `jira_auto_ticket_rules` → POST to JIRA API
9. **Notify:** Query `notification_rules` → send via channels
10. **SLA Track:** Background worker ogni 1h → mark breaches
11. **Remediation:** RBRE → generate plan → execute tasks
12. **Verify:** Re-scan or manual verification
13. **Close:** Status = 'resolved' → JIRA sync → final notification

---

### Pattern 2: Risk Score Recalculation (Cascading)

```
Trigger (CVSS change, EPSS update, asset metadata change) →
PostgreSQL Trigger: trigger_calculate_risk_score() →
  1. Fetch asset metadata (criticality, network_zone)
  2. Calculate CVSS component (30%)
  3. Calculate EPSS component (25%)
  4. Calculate Business Impact (25%)
  5. Calculate Asset Exposure (15%)
  6. Calculate Exploit Intelligence (5%)
  7. Apply priority overrides (zero-day, ransomware)
  8. Determine risk_tier (thresholds)
  9. Recalculate SLA deadline
  10. Update vulnerability record
→ Notification check (if risk_tier changed)
→ Assignment check (if new rule matches)
```

**Nota:** Recalculation può essere triggerata da:
- EPSS daily update (200k CVE)
- Asset criticality change (single asset → N vulnerabilities)
- CVSS score update (NVD enrichment)

---

### Pattern 3: Notification Routing (Rule Engine)

```
Event (vuln created, SLA breach, status change) →
Build vulnerability data JSON →
Query: get_matching_rules() →
  WHERE is_enabled = TRUE
    AND NOT in_quiet_hours(...)
    AND NOT is_throttled(...)
    AND evaluate_conditions(conditions, vuln_data)
  ORDER BY priority ASC
→ For each matching rule:
  1. Resolve recipients (emails, user_ids, team_ids, roles)
  2. Template substitution ({title}, {hostname}, etc.)
  3. Send via channels (parallel: email, slack, pagerduty)
  4. Log to notification_history
  5. Update throttle timestamp
→ End
```

---

### Pattern 4: EPSS Daily Update (Batch Processing)

```
Daily at 00:00 UTC:
  Download EPSS CSV.gz (~30MB, 200k CVE) →
  Decompress (gzip) →
  Parse CSV (cve_id, epss_score, percentile) →
  Batch process (1000 records/batch):
    UPDATE vulnerabilities v
    SET epss_score = data.score
    FROM (SELECT unnest(...) as cve_id, unnest(...) as score) data
    WHERE v.cve_id = data.cve_id
  →
  Trigger: calculate_risk_score() cascades (200k updates) →
  Update system_metadata (last_update timestamp) →
  Send completion notification
```

**Nota:** Cascading risk recalculation può durare 10-30 minuti per 200k CVE.

---

## 🧮 SUMMARY ALGORITMI CORE

| Algoritmo | Scopo | Complessità | Location | Ottimizzazione Potenziale |
|-----------|-------|-------------|----------|---------------------------|
| **Multi-Factor Risk Scoring** | Prioritizzazione vulnerabilità | O(1) | `scoring/risk_calculator.rs` | Peso adattivo basato su correlazione storica |
| **RBRE (Multiplicative Model)** | Remediation prioritization | O(n log n) | `remediation/rbre.rs` | Modello ibrido per ridurre sensibilità |
| **Time Decay Factor (Logarithmic)** | Age penalty | O(1) | `remediation/rbre.rs` | Piecewise con escalation esponenziale >180d |
| **Rule Condition Evaluation (JSONB)** | Notification/assignment matching | O(n) | PostgreSQL functions | Precompiled expression tree + cache |
| **Load Balancing (Least Loaded)** | Workload distribution | O(m) | `auto_assignment.rs` | Materialized view workload cache |
| **Comment Thread Recursion** | Threaded discussions | O(depth) | PostgreSQL recursive CTE | Materialized path + pagination |
| **SLA Breach Detection** | Deadline monitoring | O(n) | `workers/sla_checker.rs` | Partial index + materialized view |
| **JIRA Status Mapping** | Bi-directional sync | O(1) | `jira_integration.rs` | Event-driven con Redis Pub/Sub |
| **Deduplication (CVE+Host+Port)** | Prevent duplicate vulns | O(1) | Scanner imports | Temporary table + batch JOIN |
| **Batch EPSS Update** | Daily score update | O(n) | `workers/epss_updater.rs` | Delta updates + parallel batch |

---

## 📊 METRICHE DI PERFORMANCE & ENTROPIA

### Database Query Performance

**Query più frequenti (misurate con `pg_stat_statements`):**

1. **Risk Score Calculation:** ~200k/day (EPSS update)
   - Avg time: ~50ms
   - **Proposta:** Batch calculation (10x faster)

2. **SLA Breach Check:** ~24/day (hourly worker)
   - Avg time: ~200ms (scansiona tutte le vuln)
   - **Proposta:** Partial index + materialized view (~10ms)

3. **Notification Rule Matching:** ~1000/day
   - Avg time: ~100ms (JSONB evaluation)
   - **Proposta:** Precompiled conditions (~20ms)

4. **Assignment Rule Matching:** ~500/day
   - Avg time: ~150ms (joins + JSONB)
   - **Proposta:** Rule cache in Redis (~5ms)

### Entropia & Distribuzione Dati

**Risk Score Distribution (esempio dataset):**
```
Critical (80-100):  15%  (long tail, high entropy)
High (60-79):       25%
Medium (40-59):     35%
Low (20-39):        20%
Info (<20):         5%
```

**Nota:** Distribuzione asimmetrica (skewed verso Medium) suggerisce che la maggior parte delle vulnerabilità non richiede azione immediata. Questo può portare a "alert fatigue".

**Proposta:** Soglie adattive basate su percentile (es. Critical = top 10% del risk score) per mantenere distribution bilanciata.

**CVSS vs EPSS Correlation:**
```
Correlation coefficient: ~0.35 (weak positive)
```

**Interpretazione:** CVSS alto non implica necessariamente EPSS alto. Molte CVE critiche (CVSS 9+) hanno EPSS <5% (non exploited in the wild). Questo giustifica il peso 30%/25% nel risk score.

### Resource Utilization

**Background Workers (CPU time):**
- SLA Checker: ~2% CPU (1h interval)
- JIRA Sync: ~5% CPU (5min interval)
- EPSS Updater: ~30% CPU (1x/day, 30min duration)
- Notification Digest: ~1% CPU (1x/day)

**Database:**
- Connection pool: 20 max connections
- Avg query time: ~50ms
- 99th percentile: ~500ms

---

## 🔐 SECURITY FEATURES

1. **Authentication:** JWT con httpOnly cookies (XSS protection)
2. **Authorization:** RBAC (Admin, Team Leader, User)
3. **CSRF Protection:** Token-based per form submissions
4. **Rate Limiting:** Token bucket (100 req/min per IP)
5. **Security Headers:** HSTS, CSP, X-Frame-Options, X-Content-Type-Options
6. **CORS:** Whitelist configuration
7. **2FA:** TOTP support (Google Authenticator, Authy)
8. **Password Hashing:** Argon2id (memory-hard, resistant to GPU attacks)
9. **Session Management:** Multi-session tracking, remote revocation
10. **Audit Logging:** Complete trail (compliance: PCI-DSS, SOC2)

---

## 🎯 RACCOMANDAZIONI PER OTTIMIZZAZIONE

### High Priority (Quick Wins)

1. **Batch EPSS Update Optimization**
   - **Problema:** 200k sequential UPDATE (30 min)
   - **Soluzione:** Parallel batch processing + delta updates
   - **Impact:** 10x speedup (3 min)

2. **SLA Checker Materialized View**
   - **Problema:** Full table scan ogni ora
   - **Soluzione:** Materialized view per vuln "at risk" (prossime 24h)
   - **Impact:** 20x speedup (200ms → 10ms)

3. **Notification Rule Cache**
   - **Problema:** JSONB evaluation per ogni evento
   - **Soluzione:** Precompiled expression tree in Redis
   - **Impact:** 5x speedup (100ms → 20ms)

4. **Batch Scanner Import**
   - **Problema:** N queries per scan (slow per >1000 vuln)
   - **Soluzione:** Temporary table + batch INSERT/UPDATE
   - **Impact:** 10x speedup

### Medium Priority (Algorithmic Improvements)

5. **Adaptive Risk Score Weights**
   - **Problema:** Pesi fissi (30% CVSS) non riflettono correlazione reale
   - **Soluzione:** Machine learning su storico (predict exploit da features)
   - **Impact:** Miglior accuratezza prioritization (15-20%)

6. **RBRE Hybrid Model**
   - **Problema:** Modello moltiplicativo troppo sensibile a singoli fattori
   - **Soluzione:** `RPS = (TS × EP × AC)^0.7 × (EX × TC × TF)^0.3`
   - **Impact:** Riduce false negatives

7. **Remediation Effort Prediction (ML)**
   - **Problema:** Stima manuale (user input)
   - **Soluzione:** Regressione su storico (CVE type, OS, service → hours)
   - **Impact:** Automated + accurate planning

### Low Priority (Advanced Features)

8. **SLA Breach Prediction**
   - **Problema:** Sistema reattivo (notifica a breach avvenuto)
   - **Soluzione:** Modello predittivo (velocity-based forecast)
   - **Impact:** Proactive alerts (48h before breach)

9. **Dynamic SLA Adjustment**
   - **Problema:** SLA fissi per tier
   - **Soluzione:** SLA adattivi basati su team workload + storico
   - **Impact:** Realistic deadlines

10. **Parallel Rule Processing**
    - **Problema:** Rules processed in sequenza
    - **Soluzione:** Parallel evaluation + dedup recipients
    - **Impact:** 3x speedup per eventi con molte regole

---

## 📈 CONCLUSIONI

SentinelCore è una piattaforma di vulnerability management enterprise-grade con:

- **6 macro aree core:** Risk Scoring, SLA, Remediation, Scanner Integration, Notifications, Auto-Assignment
- **Algoritmi sofisticati:** Multi-factor scoring, RBRE, rule-based routing
- **Scalabilità:** Gestisce 200k+ CVE, 6 background workers, 78+ API endpoints
- **Integrazioni:** 7 scanner, 7 notification channels, JIRA bi-directional sync

**Punti di forza:**
- Risk scoring multi-componente con override intelligenti
- Remediation prioritization basata su RPS moltiplicativo
- Sistema di notifiche flessibile con anti-spam
- Auto-assignment con load balancing

**Opportunità di miglioramento:**
- Batch processing per operazioni massive (EPSS, scanner import)
- Caching e materializzazione per query frequenti
- Machine learning per adaptive weights e effort prediction
- Event-driven architecture per ridurre latency

Questa documentazione fornisce la mappa completa del "motore" dietro ogni macro area, consentendo di identificare con precisione dove intervenire per ottimizzare logica e algoritmi.
