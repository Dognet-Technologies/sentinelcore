# Packaging — release binaria SentinelCore

Distribuzione dei **build già compilati** (niente sorgenti, niente toolchain sul target).

## Costruire il pacchetto (su un build host con `cargo` + node 20)

```bash
packaging/build-release.sh            # versione = git describe (es. v1.0.1-beta)
packaging/build-release.sh v1.0.1-beta
```

Produce in `dist/`:
- `sentinelcore-<versione>-linux-x86_64.tar.gz` — binario + frontend + migration + config template + `install.sh`
- `.sha256` (checksum) e `.asc` (firma GPG, se la chiave è sul build host)

## Installare sul target (Debian 12/13 pulita, niente toolchain)

```bash
tar xzf sentinelcore-<versione>-linux-x86_64.tar.gz
cd sentinelcore-<versione>-linux-x86_64
sudo ./install.sh                       # rileva IP/NIC, genera i segreti
# oppure forzare origin/NIC:
sudo ./install.sh --server-name 10.0.0.5 --iface ens18
```

`install.sh` installa solo i **runtime** (PostgreSQL, nginx, nmap, arp-scan), crea utente/DB con **password generata**, applica le migration, scrive `production.yaml` con **JWT secret per-istanza** e CORS sull'IP rilevato, configura systemd + nginx, e crea un utente **admin** (credenziali stampate a fine install — da cambiare al primo accesso).

## Contenuto del tarball

```
install.sh                 # installer (no-toolchain)
vulnerability-manager      # binario backend (x86_64)
frontend/                  # build statico React
migrations/                # *.sql (applicate in ordine)
plugins/                   # plugin bundled (opzionale)
templates/                 # systemd unit, nginx conf, production.yaml.tmpl
VERSION
```

## Note
- Layout installato: `/opt/sentinelsuite/sentinelcore/{app,frontend}`, log in `/var/log/sentinelsuite/sentinelcore/`.
- **CORS / IP DHCP**: se l'IP cambia, aggiorna `security.cors.allowed_origins` in `production.yaml` e `sudo systemctl restart sentinelcore`.
- Per la **VM appliance** (OVA/qcow2) questa release binaria è il mattone di provisioning; il first-boot rigenera i segreti per ogni copia.
