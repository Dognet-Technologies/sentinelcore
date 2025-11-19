# 🔧 Fix: npm EBADENGINE - Incompatibilità Node.js/npm

## ❌ Errore

```
npm error code EBADENGINE
npm error engine Unsupported engine
npm error engine Not compatible with your version of node/npm: npm@11.6.3
npm error notsup Required: {"node":"^20.17.0 || >=22.9.0"}
npm error notsup Actual:   {"npm":"10.8.2","node":"v18.20.8"}
```

## 🔍 Causa

npm 11.6.3 richiede Node.js 20.17+ o 22.9+, ma hai Node.js 18.20.8.

---

## ✅ SOLUZIONE 1 - Aggiorna a Node.js 20 LTS (Raccomandato)

Node.js 20 è la versione LTS più recente e include npm 10.x compatibile.

### Usando nvm (Raccomandato)

```bash
# Installa nvm se non ce l'hai
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash

# Ricarica la shell
source ~/.bashrc  # o ~/.zshrc per zsh

# Installa Node.js 20 LTS
nvm install 20

# Usa Node.js 20
nvm use 20

# Imposta come default
nvm alias default 20

# Verifica
node --version  # Dovrebbe mostrare v20.x.x
npm --version   # Dovrebbe mostrare 10.x.x
```

### Usando apt (Ubuntu/Debian/Parrot)

```bash
# Rimuovi la versione vecchia (opzionale)
sudo apt-get remove nodejs npm

# Aggiungi repository NodeSource per Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -

# Installa Node.js 20
sudo apt-get install -y nodejs

# Verifica
node --version  # Dovrebbe mostrare v20.x.x
npm --version   # Dovrebbe mostrare 10.x.x
```

---

## ✅ SOLUZIONE 2 - Mantieni Node.js 18 con npm 9.x

Se preferisci non aggiornare Node.js, usa npm 9.x che è compatibile:

```bash
# Usa npm 9.x (ultima versione compatibile con Node 18)
sudo npm install -g npm@9

# Verifica
npm --version  # Dovrebbe mostrare 9.x.x
```

**⚠️ Nota**: Questa soluzione funziona, ma Node.js 20 è raccomandato per supporto a lungo termine.

---

## ✅ SOLUZIONE 3 - Script Automatico Aggiornato

Ho aggiornato lo script di setup per usare Node.js 20 LTS:

```bash
cd ~/Repos/Progetti/sentinelcore

# Fai pull delle ultime modifiche
git pull origin claude/check-sentinel-core-01TNDtPwCsxHbUusQCcXgvBx

# Esegui lo script aggiornato
./setup-dependencies.sh
```

Lo script ora installa automaticamente Node.js 20 LTS.

---

## 🎯 Dopo l'Aggiornamento

Una volta installato Node.js 20, installa le dipendenze del frontend:

```bash
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager-frontend

# Rimuovi node_modules e package-lock.json (opzionale ma raccomandato)
rm -rf node_modules package-lock.json

# Reinstalla dipendenze
npm install

# Verifica che funzioni
npm run build
```

---

## 📊 Versioni Raccomandate

| Componente | Versione Raccomandata | Versione Minima |
|------------|----------------------|-----------------|
| Node.js | 20.x LTS | 18.x |
| npm | 10.x | 9.x |

---

## ❓ FAQ

### Q: Perché Node.js 20 invece di 18?

**A**: Node.js 20 è la versione LTS corrente con:
- Supporto fino ad aprile 2026
- npm 10.x incluso (migliori prestazioni)
- Compatibilità con tutte le dipendenze moderne
- React 18.2.0 funziona perfettamente

### Q: Posso usare Node.js 22?

**A**: Sì, Node.js 22+ funziona perfettamente. È anche più recente.

### Q: E se uso nvm?

**A**: nvm è il modo più semplice per gestire versioni Node.js:

```bash
# Lista versioni installate
nvm list

# Cambia versione
nvm use 20

# Lista versioni disponibili
nvm list-remote
```

### Q: Ho già progetti con Node.js 18?

**A**: Con nvm puoi avere multiple versioni:

```bash
# Usa Node 20 per Sentinel Core
cd ~/Repos/Progetti/sentinelcore
nvm use 20

# Usa Node 18 per altri progetti
cd ~/altri-progetti
nvm use 18
```

Oppure crea un file `.nvmrc` nella root del progetto:

```bash
echo "20" > ~/Repos/Progetti/sentinelcore/.nvmrc

# Ora basta eseguire:
cd ~/Repos/Progetti/sentinelcore
nvm use  # Usa automaticamente la versione nel .nvmrc
```

---

## 🚀 Quick Fix (1 comando)

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash && \
source ~/.bashrc && \
nvm install 20 && \
nvm use 20 && \
nvm alias default 20 && \
cd ~/Repos/Progetti/sentinelcore/vulnerability-manager-frontend && \
rm -rf node_modules package-lock.json && \
npm install
```

---

**✅ Fatto! Ora dovresti poter installare tutte le dipendenze senza errori.**
