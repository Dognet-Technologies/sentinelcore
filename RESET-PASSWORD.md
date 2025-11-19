# 🔐 Reset Password - Sentinel Core

## ⚠️ Password Dimenticata?

Se hai perso le credenziali di accesso al frontend, segui questi passaggi:

---

## 🚀 SOLUZIONE RAPIDA

### 1️⃣ Avvia PostgreSQL

```bash
sudo systemctl start postgresql
```

### 2️⃣ Ripristina password admin

```bash
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -f reset-admin-password.sql
```

### 3️⃣ Accedi al frontend

- **URL**: http://localhost:3000
- **Username**: `admin`
- **Password**: `Admin123!`

---

## 🛠️ METODO ALTERNATIVO - Script Automatico

### Cambia password per qualsiasi utente

```bash
./change-password.sh USERNAME NUOVA_PASSWORD
```

**Esempi:**

```bash
# Reset admin
./change-password.sh admin 'MiaNuovaPassword123!'

# Reset team_leader
./change-password.sh team_leader 'SecurePass456'

# Reset user1
./change-password.sh user1 'UserPass789'
```

---

## 🔑 Generare Hash Manualmente

Se vuoi generare un hash Argon2 per una password personalizzata:

```bash
cd vulnerability-manager/init-vuln-db
cargo run --bin hash-password 'TuaPasswordQui'
```

Poi copia l'hash nell'UPDATE SQL:

```sql
UPDATE users
SET password_hash = '$argon2id$v=19$...'
WHERE username = 'admin';
```

---

## 📋 Utenti Default

Se hai eseguito il seed_data.sql, questi sono gli utenti esistenti:

| Username     | Email                  | Ruolo        | Password Default |
|--------------|------------------------|--------------|------------------|
| admin        | admin@sentinel.local   | Admin        | admin123         |
| team_leader  | leader@sentinel.local  | Team Leader  | teamleader123    |
| user1        | user1@sentinel.local   | User         | user123          |

---

## ❓ Problemi?

### PostgreSQL non si avvia

```bash
# Controlla lo status
sudo systemctl status postgresql

# Se non è installato
sudo apt install postgresql
```

### Database non esiste

```bash
# Crea il database
sudo -u postgres createdb vulnerability_manager
sudo -u postgres psql -c "CREATE USER vlnman WITH PASSWORD 'DogNET';"
sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE vulnerability_manager TO vlnman;"

# Esegui migrations
./run-migrations.sh
```

### Utente non trovato

```bash
# Lista tutti gli utenti nel database
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -c "SELECT username, email, role FROM users;"
```

---

## 🔐 Best Practices

1. **Mai** condividere password in chiaro
2. Usa password complesse (minimo 8 caratteri, maiuscole, minuscole, numeri, simboli)
3. Cambia le password default dopo la prima installazione
4. Per produzione, usa variabili d'ambiente per le password del database

---

**Quick Reference:**

```bash
# Reset rapido admin → Admin123!
psql "postgresql://vlnman:DogNET@localhost/vulnerability_manager" \
  -f reset-admin-password.sql

# Cambia password custom
./change-password.sh admin 'NuovaPassword123!'
```
