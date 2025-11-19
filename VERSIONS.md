# 📦 Versioni e Dipendenze - Sentinel Core

## 🎯 Versioni Richieste

### Backend (Rust)

| Componente | Versione | Note |
|------------|----------|------|
| **Rust** | 1.75.0+ | Edition 2021 (minimo 1.56) |
| **Cargo** | Incluso con Rust | Package manager |
| **Axum** | 0.6 | Web framework |
| **SQLx** | 0.7 | Database ORM con compile-time checks |
| **Tokio** | 1.28 | Async runtime |
| **Argon2** | 0.5 | Password hashing |
| **JsonWebToken** | 9.0 | JWT authentication |
| **quick-xml** | 0.31 | XML export |
| **printpdf** | 0.7 | PDF generation |
| **reqwest** | 0.11 | HTTP client per notifiche |
| **lettre** | 0.11 | Email sender |

### Frontend (React)

| Componente | Versione | Note |
|------------|----------|------|
| **Node.js** | 18.x LTS | Minimo 16.x |
| **npm** | 9+ | Package manager |
| **React** | 18.2.0 | UI library |
| **TypeScript** | 4.9.5 | Type safety |
| **Material-UI** | 5.17 | Component library |
| **Cytoscape.js** | 3.27 | Network graph visualization |
| **xterm.js** | 5.3.0 | Terminal emulator |
| **React Router** | 6.30 | Routing |
| **Axios** | 1.9.0 | HTTP client |
| **Chart.js** | 4.4.9 | Grafici |
| **Framer Motion** | 12.17 | Animazioni |

### Database

| Componente | Versione | Note |
|------------|----------|------|
| **PostgreSQL** | 14+ | Database principale (minimo 9.6) |
| **libpq-dev** | Latest | Librerie sviluppo PostgreSQL |

---

## 🚀 Installazione Rapida

### Metodo 1: Script Automatico (Raccomandato)

```bash
cd ~/Repos/Progetti/sentinelcore

# Rendi eseguibile lo script
chmod +x setup-dependencies.sh

# Esegui l'installazione completa
./setup-dependencies.sh
```

Lo script installa automaticamente:
- ✅ Rust + Cargo
- ✅ Node.js 18 LTS + npm
- ✅ PostgreSQL 14+
- ✅ Tutte le dipendenze di sistema
- ✅ Configurazione database
- ✅ Migrations

---

### Metodo 2: Installazione Manuale

#### 1. Installa Rust

```bash
# Download e installazione
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

# Carica nel PATH
source $HOME/.cargo/env

# Verifica versione
rustc --version  # Dovrebbe essere 1.75+

# Installa componenti
rustup component add rustfmt clippy
```

#### 2. Installa Node.js 18 LTS

**Ubuntu/Debian/Parrot:**
```bash
# Aggiungi repository NodeSource
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -

# Installa Node.js
sudo apt-get install -y nodejs

# Aggiorna npm
sudo npm install -g npm@latest

# Verifica versioni
node --version   # Dovrebbe essere v18.x
npm --version    # Dovrebbe essere 9+
```

**macOS:**
```bash
# Usa Homebrew
brew install node@18

# Oppure usa nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
```

**Windows:**
```powershell
# Scarica installer da nodejs.org
# Oppure usa Chocolatey
choco install nodejs-lts
```

#### 3. Installa PostgreSQL 14+

**Ubuntu/Debian/Parrot:**
```bash
# Aggiungi repository PostgreSQL
sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'
wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -

# Installa PostgreSQL
sudo apt-get update
sudo apt-get install -y postgresql-14 postgresql-contrib-14 libpq-dev

# Avvia servizio
sudo systemctl start postgresql
sudo systemctl enable postgresql

# Verifica
psql --version
```

**macOS:**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Windows:**
```powershell
# Scarica installer da postgresql.org
# Oppure usa Chocolatey
choco install postgresql14
```

#### 4. Installa Dipendenze di Sistema

**Ubuntu/Debian/Parrot:**
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    pkg-config \
    libssl-dev \
    libpq-dev \
    git \
    curl \
    wget
```

**macOS:**
```bash
xcode-select --install
brew install openssl pkg-config
```

**Windows:**
```powershell
# Installa Visual Studio Build Tools
# https://visualstudio.microsoft.com/downloads/
# Seleziona: C++ build tools
```

#### 5. Configura Database

```bash
# Crea utente e database
sudo -u postgres psql << EOF
CREATE USER vlnman WITH PASSWORD 'DogNET';
CREATE DATABASE vulnerability_manager;
GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;
\q
EOF

# Crea file .env
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager
echo "DATABASE_URL=postgresql://vlnman:DogNET@localhost/vulnerability_manager" > .env
```

#### 6. Installa Dipendenze Backend

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager

# Scarica dipendenze Rust
cargo fetch

# Compila (può richiedere 5-10 minuti la prima volta)
cargo build --release
```

#### 7. Installa Dipendenze Frontend

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager-frontend

# Installa dipendenze npm (può richiedere 2-5 minuti)
npm install
```

#### 8. Esegui Migrations

```bash
cd ~/Repos/Progetti/sentinelcore
./run-migrations.sh
```

---

## 🔍 Verifica Versioni

Dopo l'installazione, verifica che tutto sia corretto:

```bash
# Rust
rustc --version
# Output atteso: rustc 1.75.0 o superiore

cargo --version
# Output atteso: cargo 1.75.0 o superiore

# Node.js
node --version
# Output atteso: v18.x.x

npm --version
# Output atteso: 9.x.x o superiore

# PostgreSQL
psql --version
# Output atteso: psql (PostgreSQL) 14.x o superiore

# Verifica database
psql -U vlnman -d vulnerability_manager -c "SELECT version();"
# Dovrebbe connettersi senza errori
```

---

## 📊 Dipendenze Complete Backend (Cargo.toml)

```toml
[dependencies]
# Web Framework
tokio = { version = "1.28", features = ["full"] }
axum = { version = "0.6", features = ["multipart"] }
tower = "0.4"
tower-http = { version = "0.4", features = ["cors"] }

# Database
sqlx = { version = "0.7", features = ["runtime-tokio-native-tls", "postgres", "uuid", "chrono", "json", "macros"] }

# Utilities
uuid = { version = "1.3", features = ["v4", "serde"] }
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
chrono = { version = "0.4", features = ["serde"] }
dotenv = "0.15"
anyhow = "1.0"
tracing = "0.1"
tracing-subscriber = "0.3"

# Authentication
jsonwebtoken = "9.0"
argon2 = "0.5"
rand = "0.8"

# Export Formats
quick-xml = { version = "0.31", features = ["serialize"] }
csv = "1.3"
printpdf = "0.7"

# Notifications
reqwest = { version = "0.11", features = ["json"] }
lettre = { version = "0.11", features = ["tokio1-native-tls"] }
```

---

## 📊 Dipendenze Complete Frontend (package.json)

```json
{
  "dependencies": {
    "@mui/material": "^5.17.1",
    "@mui/icons-material": "^5.17.1",
    "react": "^18.2.0",
    "react-dom": "^18.2.0",
    "react-router-dom": "^6.30.1",
    "typescript": "^4.9.5",
    "axios": "^1.9.0",
    "cytoscape": "^3.27.0",
    "xterm": "^5.3.0",
    "chart.js": "^4.4.9",
    "framer-motion": "^12.17.3"
  }
}
```

---

## 🆘 Risoluzione Problemi

### Problema: Rust non trovato dopo installazione

```bash
# Carica Rust nel PATH
source $HOME/.cargo/env

# Aggiungi al .bashrc o .zshrc
echo 'source $HOME/.cargo/env' >> ~/.bashrc
```

### Problema: Node.js versione sbagliata

```bash
# Usa nvm per gestire versioni Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
source ~/.bashrc

nvm install 18
nvm use 18
nvm alias default 18
```

### Problema: Errori compilazione SQLx

```bash
# Assicurati che PostgreSQL sia attivo
sudo systemctl start postgresql

# Verifica .env
cat ~/Repos/Progetti/sentinelcore/vulnerability-manager/.env
# Dovrebbe contenere: DATABASE_URL=postgresql://vlnman:DogNET@localhost/vulnerability_manager

# Oppure usa modalità offline
export SQLX_OFFLINE=true
cargo build
```

### Problema: npm EACCES permissions

```bash
# Correggi permessi npm
mkdir ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc
```

---

## 📖 Risorse Utili

- **Rust**: https://www.rust-lang.org/learn/get-started
- **Node.js**: https://nodejs.org/en/download/
- **PostgreSQL**: https://www.postgresql.org/download/
- **Axum**: https://docs.rs/axum/0.6/axum/
- **React**: https://react.dev/
- **Material-UI**: https://mui.com/

---

## ✅ Checklist Installazione

Usa questa checklist per verificare l'installazione:

- [ ] Rust 1.75+ installato (`rustc --version`)
- [ ] Cargo funzionante (`cargo --version`)
- [ ] Node.js 18+ installato (`node --version`)
- [ ] npm 9+ installato (`npm --version`)
- [ ] PostgreSQL 14+ installato (`psql --version`)
- [ ] Database `vulnerability_manager` creato
- [ ] Utente `vlnman` creato con password `DogNET`
- [ ] File `.env` presente in `vulnerability-manager/`
- [ ] Dipendenze Rust scaricate (`cargo fetch`)
- [ ] Dipendenze npm installate (`npm install`)
- [ ] Migrations eseguite (`./run-migrations.sh`)
- [ ] Backend compila senza errori (`cargo build`)
- [ ] Frontend compila senza errori (`npm run build`)

---

**🎉 Installazione completata! Sei pronto per lanciare Sentinel Core!**
