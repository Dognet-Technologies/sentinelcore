# 🔧 Fix Errori di Compilazione - Sentinel Core

## ❌ Problemi Riscontrati

1. **Errori di sintassi**: `cannot find value pool in this scope`
2. **Errori SQLx**: `set DATABASE_URL to use query macros online`
3. **Conflitti git**: `encountered diff marker in state.rs`

---

## ✅ SOLUZIONI APPLICATE

### 1️⃣ Fix Errori di Sintassi (`pool*app_state.pool`)

**Problema**: Nei file handlers c'era `&*pool*app_state.pool` invece di `&*app_state.pool`

**Risolto in**:
- `src/handlers/team.rs` ✅
- `src/handlers/asset.rs` ✅
- `src/handlers/plugin.rs` ✅
- `src/handlers/audit.rs` ✅

**Comando usato**:
```bash
sed -i 's/&\*pool\*app_state\.pool/\&\*app_state.pool/g' src/handlers/*.rs
```

### 2️⃣ Fix Errori SQLx

**Problema**: SQLx non trovava `DATABASE_URL` per verificare le query al compile-time

**Soluzione**: Creato file `.env` con:
```env
DATABASE_URL=postgresql://vlnman:DogNET@localhost/vulnerability_manager
```

---

## 🚀 COME COMPILARE ORA

### METODO 1 - Con PostgreSQL Attivo (Raccomandato)

```bash
# 1. Avvia PostgreSQL
sudo systemctl start postgresql

# 2. Vai nella directory del backend
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

# 3. Compila
cargo build
```

✅ **Vantaggi**: Controllo delle query SQL al compile-time, più sicuro

### METODO 2 - Senza PostgreSQL (Modalità Offline)

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

# Usa lo script pronto
./compile-offline.sh
```

Oppure manualmente:
```bash
export SQLX_OFFLINE=true
cargo build
```

⚠️ **Nota**: In modalità offline, SQLx non può verificare le query SQL

### METODO 3 - Prepara Cache SQLx (Una volta sola)

Se vuoi compilare velocemente in futuro senza PostgreSQL:

```bash
# 1. Avvia PostgreSQL UNA VOLTA
sudo systemctl start postgresql

# 2. Genera la cache delle query
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager
cargo sqlx prepare

# 3. Da ora in poi puoi compilare anche senza PostgreSQL
export SQLX_OFFLINE=true
cargo build
```

Questo crea un file `.sqlx/query-*.json` con tutte le query pre-validate.

---

## 🐛 ALTRI PROBLEMI COMUNI

### Problema: Conflitti git in `state.rs`

**Errore**:
```
error: encountered diff marker
  --> src/state.rs:25:1
```

**Soluzione**: Esegui sul TUO computer locale:
```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

cat > src/state.rs << 'EOF'
//src/state.rs
use axum::extract::FromRef;
use sqlx::PgPool;
use std::sync::Arc;
use crate::auth;

// Shared application state
#[derive(Clone)]
pub struct AppState {
    pub pool: Arc<PgPool>,
    pub auth: Arc<auth::Auth>,
}

// Implement FromRef per permettere l'estrazione di singoli state
impl FromRef<AppState> for Arc<PgPool> {
    fn from_ref(state: &AppState) -> Self {
        state.pool.clone()
    }
}

impl FromRef<AppState> for Arc<auth::Auth> {
    fn from_ref(state: &AppState) -> Self {
        state.auth.clone()
    }
}
EOF
```

### Problema: PostgreSQL non si avvia

```bash
# Controlla lo stato
sudo systemctl status postgresql

# Se non è installato
sudo apt install postgresql postgresql-contrib

# Avvia
sudo systemctl start postgresql

# Abilita all'avvio
sudo systemctl enable postgresql
```

### Problema: Database non esiste

```bash
# Crea database e utente
sudo -u postgres createdb vulnerability_manager
sudo -u postgres psql << EOF
CREATE USER vlnman WITH PASSWORD 'DogNET';
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
EOF

# Esegui migrations
cd ~/Repos/Progetti/sentinelcore
./run-migrations.sh
```

---

## 📋 CHECKLIST COMPLETA

Prima di compilare, verifica:

- [ ] PostgreSQL installato e avviato (o usa modalità offline)
- [ ] File `.env` presente con `DATABASE_URL`
- [ ] Nessun conflitto git in `state.rs`
- [ ] Nessun errore di sintassi `pool*app_state.pool`
- [ ] Database `vulnerability_manager` creato
- [ ] Migrations eseguite

---

## 🎯 QUICK FIX - Tutto in Un Comando

Sul **tuo computer locale**:

```bash
cd ~/Repos/Progetti/sentinelcore

# Fix state.rs (se hai conflitti git)
cat > vulnerability-manager/src/state.rs << 'EOF'
//src/state.rs
use axum::extract::FromRef;
use sqlx::PgPool;
use std::sync::Arc;
use crate::auth;

#[derive(Clone)]
pub struct AppState {
    pub pool: Arc<PgPool>,
    pub auth: Arc<auth::Auth>,
}

impl FromRef<AppState> for Arc<PgPool> {
    fn from_ref(state: &AppState) -> Self {
        state.pool.clone()
    }
}

impl FromRef<AppState> for Arc<auth::Auth> {
    fn from_ref(state: &AppState) -> Self {
        state.auth.clone()
    }
}
EOF

# Crea .env
echo "DATABASE_URL=postgresql://vlnman:DogNET@localhost/vulnerability_manager" > vulnerability-manager/.env

# Avvia PostgreSQL
sudo systemctl start postgresql

# Compila
cd vulnerability-manager
cargo build
```

---

## 📚 RISORSE

- **Backend**: `~/Repos/Progetti/sentinelcore/vulnerability-manager`
- **Frontend**: `~/Repos/Progetti/sentinelcore/vulnerability-manager-frontend`
- **Migrations**: `~/Repos/Progetti/sentinelcore/vulnerability-manager/migrations`
- **Config**: `~/Repos/Progetti/sentinelcore/vulnerability-manager/config/default.yaml`

---

**🎉 Fatto! Ora dovresti poter compilare senza errori!**

Se hai ancora problemi, verifica che hai fatto il pull delle ultime modifiche:
```bash
git pull origin claude/check-sentinel-core-01TNDtPwCsxHbUusQCcXgvBx
```
