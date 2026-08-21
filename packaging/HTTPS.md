# HTTPS — certificato self-signed (default) e Let's Encrypt (dominio pubblico)

## Default: self-signed, uso LAN

SentinelCore è pensato per l'uso interno in rete locale. `install.sh` genera
automaticamente, a ogni installazione, un certificato TLS **self-signed**
(`/etc/ssl/sentinelcore/sentinelcore.{crt,key}`, validità 825 giorni) con
`CN`/`SAN` impostati sull'IP o hostname rilevato (`--server-name`, o l'IP
LAN auto-rilevato). nginx fa da terminatore TLS: la porta 80 fa redirect
301 verso la 443, e tutto il traffico applicativo passa in HTTPS.

Con un certificato self-signed il browser mostra un avviso "connessione non
sicura" al primo accesso — è atteso, non un errore di installazione. Basta
accettare l'eccezione (o importare il certificato nel trust store locale)
per non rivedere l'avviso.

**Let's Encrypt NON può emettere certificati per questo scenario**: richiede
un dominio pubblico risolvibile via DNS e le porte 80/443 raggiungibili da
internet per la validazione ACME. Un IP nudo (pubblico o privato) non è
accettato da Let's Encrypt in nessun caso.

## Passare a un dominio pubblico + Let's Encrypt/certbot

Solo se vuoi esporre l'istanza su internet con un nome a dominio reale.

### Prerequisiti

- Un dominio (o sottodominio) con un record DNS A/AAAA che punta all'IP
  pubblico del server (es. `sentinelcore.tuodominio.it → 203.0.113.10`).
- Porte 80 e 443 raggiungibili da internet (firewall/router/NAT
  configurati di conseguenza).
- SentinelCore già installato con `install.sh` (il certificato self-signed
  di default resta come fallback finché non lo sostituisci).

### 1. Reinstalla (o riconfigura) con il dominio come server name

Se non l'hai già fatto in fase di install:

```bash
sudo ./install.sh --server-name sentinelcore.tuodominio.it
```

Oppure, su un'istanza già esistente, aggiorna a mano `SERVER_NAME` in
`/opt/sentinelsuite/sentinelcore/app/config/production.yaml`
(`security.cors.allowed_origins`) con `https://sentinelcore.tuodominio.it`.

### 2. Installa certbot

```bash
sudo apt-get install -y certbot
```

### 3. Richiedi il certificato (modalità webroot)

nginx serve già il frontend statico da
`/opt/sentinelsuite/sentinelcore/frontend`; usiamo quella directory come
webroot per la validazione ACME HTTP-01, senza toccare la configurazione
nginx esistente. Il blocco `location /.well-known/acme-challenge/` sulla
porta 80 è già pre-configurato da `install.sh` (esente dal redirect verso
HTTPS) proprio per questo scopo.

```bash
sudo certbot certonly --webroot \
  -w /opt/sentinelsuite/sentinelcore/frontend \
  -d sentinelcore.tuodominio.it \
  --email tua-email@esempio.it --agree-tos --no-eff-email
```

Il certificato viene scritto in
`/etc/letsencrypt/live/sentinelcore.tuodominio.it/{fullchain,privkey}.pem`.

### 4. Punta nginx al certificato Let's Encrypt

Modifica `/etc/nginx/sites-available/sentinelcore`, sostituendo le due
righe `ssl_certificate`/`ssl_certificate_key` (quelle che puntano a
`/etc/ssl/sentinelcore/...`) con:

```nginx
ssl_certificate     /etc/letsencrypt/live/sentinelcore.tuodominio.it/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/sentinelcore.tuodominio.it/privkey.pem;
```

Poi:

```bash
sudo nginx -t && sudo systemctl reload nginx
```

### 5. Rinnovo automatico

Il pacchetto `certbot` installa già un timer systemd
(`certbot.timer`/`certbot-renew.timer` a seconda della distro) che
controlla il rinnovo due volte al giorno. Verifica che sia attivo:

```bash
systemctl list-timers | grep certbot
sudo certbot renew --dry-run   # simula un rinnovo senza applicarlo
```

Il rinnovo automatico riscrive gli stessi file in
`/etc/letsencrypt/live/...`, quindi nginx non richiede modifiche
ulteriori — serve solo un `reload` dopo ogni rinnovo reale, che certbot
esegue da solo se è installato l'hook nginx (`certbot install --nginx` non
necessario in modalità webroot; in alternativa aggiungi un deploy-hook):

```bash
echo 'systemctl reload nginx' | sudo tee /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
sudo chmod +x /etc/letsencrypt/renewal-hooks/deploy/reload-nginx.sh
```

## Se l'IP cambia (DHCP, self-signed)

Il certificato self-signed ha `CN`/`SAN` legati all'IP/hostname rilevato al
momento dell'installazione. Se l'IP cambia, rigeneralo con lo stesso
comando usato da `install.sh`:

```bash
SERVER_NAME="<nuovo-ip-o-host>"
SAN_TYPE="DNS"; echo "$SERVER_NAME" | grep -qE '^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$' && SAN_TYPE="IP"
sudo openssl req -x509 -nodes -newkey rsa:2048 -days 825 \
  -keyout /etc/ssl/sentinelcore/sentinelcore.key \
  -out /etc/ssl/sentinelcore/sentinelcore.crt \
  -subj "/CN=$SERVER_NAME" -addext "subjectAltName=$SAN_TYPE:$SERVER_NAME"
sudo systemctl reload nginx
```

Aggiorna anche `security.cors.allowed_origins` in `production.yaml` con il
nuovo `https://<ip-o-host>` e riavvia il servizio:

```bash
sudo systemctl restart sentinelcore
```
