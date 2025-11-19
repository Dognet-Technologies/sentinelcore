# ✅ Fix: Type Mismatches tra Rust Models e PostgreSQL Schema

## 🎯 Problema Risolto

Gli errori di compilazione erano causati da:

1. **❌ Colonne mancanti nel database**: `phone_number`, `device_info`, `last_activity`, `bio`
2. **❌ Type mismatch IP addresses**: Rust usava `String`, PostgreSQL usa `INET`
3. **❌ SQL query non compatibile**: `ILIKE` non funziona su tipo `INET`

---

## ✅ Soluzioni Applicate

### 1️⃣ Migration 005: Colonne Mancanti

**File creato**: `vulnerability-manager/migrations/005_add_missing_columns.sql`

Aggiunge le colonne che i modelli Rust si aspettavano ma non esistevano nel database:

```sql
-- Tabella users
ALTER TABLE users
ADD COLUMN IF NOT EXISTS phone_number VARCHAR(20),
ADD COLUMN IF NOT EXISTS bio TEXT;

-- Tabella user_sessions
ALTER TABLE user_sessions
ADD COLUMN IF NOT EXISTS device_info JSONB,
ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP DEFAULT NOW();
```

**Colonne aggiunte**:
- `users.phone_number` → Per contatto utente e 2FA SMS
- `users.bio` → Biografia utente
- `user_sessions.device_info` → Info dispositivo (browser, OS, device type)
- `user_sessions.last_activity` → Timestamp ultima attività per timeout sessione

---

### 2️⃣ Aggiornamento Rust Models: String → IpNetwork

**File modificati**:
- `src/models/user.rs`
- `src/models/vulnerability.rs`
- `src/models/asset.rs`

**Prima** (SBAGLIATO):
```rust
pub ip_address: String,  // ❌ Non compatibile con PostgreSQL INET
```

**Dopo** (CORRETTO):
```rust
use ipnetwork::IpNetwork;

pub ip_address: IpNetwork,  // ✅ Compatibile con PostgreSQL INET
```

**Tipi aggiornati**:
- `UserSession.ip_address: String` → `Option<IpNetwork>`
- `IpWhitelist.ip_address: String` → `IpNetwork`
- `Vulnerability.ip_address: String` → `IpNetwork`
- `NewVulnerability.ip_address: String` → `IpNetwork`
- `Asset.ip_address: Option<String>` → `Option<IpNetwork>`
- `NewAsset.ip_address: Option<String>` → `Option<IpNetwork>`
- `UpdateAsset.ip_address: Option<String>` → `Option<IpNetwork>`

**Feature già aggiunta in Cargo.toml**:
```toml
sqlx = { version = "0.7", features = [..., "ipnetwork"] }
```

---

### 3️⃣ Fix SQL Query: INET Pattern Matching

**File modificato**: `src/handlers/vulnerability.rs`

**Prima** (SBAGLIATO):
```sql
WHERE ip_address ILIKE $1  -- ❌ operator does not exist: inet ~~* unknown
```

**Dopo** (CORRETTO):
```sql
WHERE ip_address::TEXT ILIKE $1  -- ✅ Cast INET to TEXT for pattern matching
```

**Spiegazione**: L'operatore `ILIKE` non funziona direttamente su tipo `INET`. Bisogna fare il cast a `TEXT` prima di usare pattern matching.

---

### 4️⃣ Aggiornamento run-migrations.sh

**File modificato**: `run-migrations.sh`

Ora esegue **6 migrations** invece di 5:

```bash
[1/6] 001_initial_schema.sql      # Schema base
[2/6] 002_add_user_features.sql   # User features & security
[3/6] 003_network_topology.sql    # Network scanning
[4/6] 004_convert_to_inet.sql     # IP address → INET conversion
[5/6] 005_add_missing_columns.sql # Colonne mancanti (NUOVO!)
[6/6] seed_data.sql                # Dati di test
```

---

## 🚀 Prossimi Passi

### Step 1: Avvia PostgreSQL

```bash
# Verifica se PostgreSQL è installato
which psql

# Avvia PostgreSQL (scegli il metodo appropriato)
# Metodo 1: systemctl (Ubuntu/Debian)
sudo systemctl start postgresql
sudo systemctl status postgresql

# Metodo 2: service (Parrot OS)
sudo service postgresql start
sudo service postgresql status

# Metodo 3: pg_ctl (manual)
pg_ctl -D /var/lib/postgresql/data start
```

---

### Step 2: Esegui Migration 005

**Opzione A - Script rapido**:
```bash
cd ~/Repos/Progetti/sentinelcore
./run-migration-005.sh
```

**Opzione B - Script completo** (ri-esegue tutte le migrations):
```bash
cd ~/Repos/Progetti/sentinelcore
./run-migrations.sh
```

**Opzione C - Manuale**:
```bash
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -f vulnerability-manager/migrations/005_add_missing_columns.sql
```

---

### Step 3: Verifica Colonne Aggiunte

```bash
# Verifica users
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -c "\d users" | grep -E "phone_number|bio"

# Verifica user_sessions
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -c "\d user_sessions" | grep -E "device_info|last_activity"

# Output atteso:
# phone_number         | character varying(20) |
# bio                  | text                  |
# device_info          | jsonb                 |
# last_activity        | timestamp             |
```

---

### Step 4: Compila il Backend

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

# Verifica (più veloce)
cargo check

# Build completo
cargo build --release
```

**⚠️ Importante**: SQLx richiede che PostgreSQL sia **attivo e raggiungibile** durante la compilazione per verificare le query SQL a compile-time.

Se vedi errori tipo:
```
error: error communicating with database: Connection refused (os error 111)
```

Significa che PostgreSQL non è raggiungibile. Verifica con:
```bash
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" -c "SELECT 1"
```

---

## 📊 Riepilogo Modifiche

| File | Tipo | Descrizione |
|------|------|-------------|
| `005_add_missing_columns.sql` | Creato | Migration per colonne mancanti |
| `run-migrations.sh` | Modificato | Aggiunta migration 005 (ora 6 migrations) |
| `run-migration-005.sh` | Creato | Script rapido per migration 005 |
| `src/models/user.rs` | Modificato | String → IpNetwork per IP addresses |
| `src/models/vulnerability.rs` | Modificato | String → IpNetwork per IP addresses |
| `src/models/asset.rs` | Modificato | String → IpNetwork per IP addresses |
| `src/handlers/vulnerability.rs` | Modificato | INET::TEXT cast per pattern matching |

---

## 🔍 Verifica Finale

Dopo aver compilato con successo:

```bash
# 1. Verifica versioni
rustc --version   # 1.75.0+
node --version    # v20.x.x
npm --version     # 10.x.x
psql --version    # 14+

# 2. Verifica migrations
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" -c "\dt"

# Dovrebbe mostrare tutte le tabelle:
# users, user_sessions, audit_logs, reputation_events,
# vulnerabilities, assets, teams, etc.

# 3. Verifica colonne users
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -c "SELECT column_name, data_type FROM information_schema.columns
      WHERE table_name = 'users'
      ORDER BY ordinal_position;"

# 4. Test compilazione
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager
cargo build --release

# 5. Avvia backend
cd ~/Repos/Progetti/sentinelcore
./start-backend.sh
```

---

## 🎓 Spiegazione Tecnica

### Perché IpNetwork invece di String?

1. **Type Safety**: `IpNetwork` è type-safe e previene errori di parsing
2. **PostgreSQL INET**: Compatibilità nativa con tipo `INET` di PostgreSQL
3. **Network Operations**: Supporta operazioni di rete (subnet, contains, etc.)
4. **Validazione**: Automatica validazione formato IP/CIDR

### Formato IpNetwork Supportato

```rust
// Single IP
let ip: IpNetwork = "192.168.1.1".parse().unwrap();  // → 192.168.1.1/32

// CIDR notation
let subnet: IpNetwork = "192.168.1.0/24".parse().unwrap();  // → 192.168.1.0/24

// IPv6
let ipv6: IpNetwork = "2001:db8::1".parse().unwrap();  // → 2001:db8::1/128
```

### Serializzazione JSON

`IpNetwork` si serializza automaticamente come stringa in JSON:

```json
{
  "ip_address": "192.168.1.100",
  "subnet": "10.0.0.0/8"
}
```

---

## ❓ Troubleshooting

### Errore: "Connection refused (os error 111)"

**Causa**: PostgreSQL non è in esecuzione o non accetta connessioni TCP/IP

**Soluzione**:
```bash
# Avvia PostgreSQL
sudo systemctl start postgresql

# Verifica connessione
psql -h localhost -U vlnman -d vulnerability_manager -c "SELECT 1"
# Password: DogNET
```

---

### Errore: "Peer authentication failed"

**Causa**: PostgreSQL usa autenticazione `peer` invece di `md5`

**Soluzione**: Usa `-h localhost` per forzare TCP:
```bash
psql -h localhost -U vlnman -d vulnerability_manager
```

---

### Errore: "column does not exist"

**Causa**: Migration 005 non è stata eseguita

**Soluzione**:
```bash
./run-migration-005.sh
```

---

### Errore: "the trait bound 'String: From<IpNetwork>'"

**Causa**: Codice sta cercando di convertire IpNetwork in String automaticamente

**Soluzione**: Usa `.to_string()` per conversione esplicita:
```rust
let ip_string: String = ip_network.to_string();
```

---

## ✅ Checklist Completamento

- [x] Migration 005 creata
- [x] run-migrations.sh aggiornato
- [x] Modelli Rust aggiornati a IpNetwork
- [x] SQL query fix per INET casting
- [ ] **PostgreSQL avviato** ← **TU DEVI FARE QUESTO**
- [ ] **Migration 005 eseguita** ← **TU DEVI FARE QUESTO**
- [ ] **Compilazione backend** ← **TU DEVI FARE QUESTO**
- [ ] **Test applicazione** ← **TU DEVI FARE QUESTO**

---

## 📚 Documentazione Aggiuntiva

- **SQLx INET Support**: https://docs.rs/sqlx/latest/sqlx/postgres/types/index.html
- **IpNetwork Crate**: https://docs.rs/ipnetwork/latest/ipnetwork/
- **PostgreSQL INET Type**: https://www.postgresql.org/docs/current/datatype-net-types.html

---

**✅ Tutti i fix sono stati applicati. Ora devi solo avviare PostgreSQL, eseguire la migration, e compilare!**
