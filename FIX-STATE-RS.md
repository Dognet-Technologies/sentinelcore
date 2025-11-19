# 🔧 Fix per state.rs - Risoluzione Conflitto Git

## ❌ Errore

```
error: encountered diff marker
  --> src/state.rs:25:1
   |
25 | <<<<<<< HEAD
```

## ✅ SOLUZIONE RAPIDA

Apri il file `vulnerability-manager/src/state.rs` e **rimuovi completamente le righe 25-28** (i marker di conflitto), lasciando solo il codice corretto.

### Il file corretto deve essere così:

```rust
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
```

## 🛠️ METODO AUTOMATICO

Dalla root del progetto, esegui:

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

# Risolvi il conflitto automaticamente
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

# Verifica che il file sia corretto
cargo check
```

## 📝 METODO MANUALE

1. Apri `vulnerability-manager/src/state.rs` con il tuo editor
2. Vai alle righe 25-28
3. Cerca queste righe:
   ```
   <<<<<<< HEAD

   =======
   >>>>>>> aae085e2576a3b92b84f2f1e4b48ca66c4c09a75
   ```
4. **Elimina completamente** queste 4 righe
5. Assicurati che alla fine il file termini con:
   ```rust
   impl FromRef<AppState> for Arc<auth::Auth> {
       fn from_ref(state: &AppState) -> Self {
           state.auth.clone()
       }
   }
   ```
6. Salva il file

## ✅ Verifica

Dopo aver risolto:

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager
cargo build
```

Dovrebbe compilare senza errori!

---

**Nota**: Questo conflitto si è creato probabilmente durante un `git pull` o `git merge`. I marker `<<<<<<<`, `=======`, e `>>>>>>>` indicano le due versioni in conflitto. Devi scegliere quale codice tenere (in questo caso, tieni la versione con le due implementazioni `FromRef`).
