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

---

# VM appliance (OVA / qcow2)

Distribuisce SentinelCore come immagine VM pronta all'uso. Richiede il tarball
binario (`dist/*.tar.gz`) già compilato con `build-release.sh`.

## Costruire la VM (sul build host)

```bash
# 1. Prima costruisci il tarball (se non esiste ancora)
packaging/build-release.sh v1.0.1-beta

# 2. Poi costruisci la VM appliance
packaging/build-vm.sh v1.0.1-beta
```

Produce in `dist/`:
- `sentinelcore-<versione>-linux-x86_64.qcow2` — per KVM / Proxmox
- `sentinelcore-<versione>-linux-x86_64.ova`   — per VirtualBox / VMware
- `sentinelcore-<versione>-linux-x86_64.sha256` — checksum combinato
- `build-vm-console.log` — log della VM di build (debug)

### Dipendenze build host (una tantum)

```bash
sudo apt-get install qemu-system-x86 qemu-utils cloud-image-utils
```

KVM accelera la build (~5 min vs ~20+ min senza). La prima esecuzione scarica
l'immagine base Debian 13 (~400 MB) nella cache `~/.cache/sentinelcore-build/`.

### Override URL immagine Debian

```bash
DEBIAN_CLOUD_IMG_URL=https://tuo-mirror/debian-13.qcow2 packaging/build-vm.sh
DEBIAN_CLOUD_IMG_CACHE=/path/to/cached.qcow2 packaging/build-vm.sh
```

## Usare la VM

**VirtualBox:** File → Importa appliance → seleziona `.ova`  
**VMware:** File → Open → seleziona `.ova`  
**Proxmox/KVM:** importa `.qcow2` come disco, oppure:

```bash
qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm \
  -drive file=sentinelcore-v1.0.1-beta-linux-x86_64.qcow2,format=qcow2 \
  -netdev user,id=net0 -device virtio-net-pci,netdev=net0
```

## Primo avvio — first-boot

Al primo avvio di ogni copia (clone / importazione), `sentinelcore-first-boot.service`
rigenera automaticamente:

- password utente PostgreSQL → aggiornata in `production.yaml`
- JWT secret key → aggiornata in `production.yaml`
- SSH host keys (rimosse durante build, rigenerate alla prima partenza)
- machine-id (unico per ogni clone)
- password admin → nuovo account con password casuale conforme alla policy

Le credenziali iniziali sono stampate su **console** e salvate in `/etc/motd`:

```
╔══════════════════════════════════════════════════════════════╗
║          SentinelCore — Credenziali iniziali istanza         ║
╠══════════════════════════════════════════════════════════════╣
  URL:        http://192.168.x.x
  Utente:     admin
  Password:   XxXxXxXx1234Aa1!
  CAMBIA la password al primo accesso (Impostazioni → Profilo).
╚══════════════════════════════════════════════════════════════╝
```

Il servizio si disabilita da solo dopo la prima esecuzione: dal secondo avvio
sentinelcore parte normalmente senza rigenerare nulla.

## Struttura appliance

```
packaging/
├── build-release.sh                  # tarball binario (passo 1)
├── build-vm.sh                       # VM appliance (passo 2)
├── install.sh                        # installer no-toolchain (dentro il tarball)
├── templates/                        # systemd, nginx, production.yaml.tmpl
└── appliance/
    ├── provision.sh                  # eseguito dentro la VM di build
    ├── first-boot.sh                 # eseguito al primo avvio di ogni clone
    └── sentinelcore-first-boot.service
```
