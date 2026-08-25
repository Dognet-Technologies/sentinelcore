# 1. Installazione

SentinelCore si distribuisce in due modi. Scegli quello più adatto al tuo contesto.

| Modalità | Quando usarla | Cosa serve |
|---|---|---|
| **A — VM appliance** (OVA / qcow2) | Vuoi provare o mettere in produzione SentinelCore nel modo più rapido possibile, senza occuparti di sistema operativo, dipendenze o configurazione manuale | Un hypervisor (VirtualBox, VMware, Proxmox, KVM) |
| **B — Pacchetto binario** | Hai già un server Linux (fisico o virtuale) su cui vuoi installare SentinelCore, magari insieme ad altri servizi | Un host Debian 12/13 pulito con accesso `sudo` |

Non serve in nessuno dei due casi installare compilatori, Rust, Node.js o altri strumenti di sviluppo: entrambi i pacchetti contengono i binari già compilati.

---

## Modalità A — VM appliance (consigliata)

### Requisiti minimi

| Risorsa | Minimo | Consigliato |
|---|---|---|
| vCPU | 2 | 4 |
| RAM | 2 GB | 4 GB |
| Disco | 10 GB | 20 GB |
| Rete | Un indirizzo IP raggiungibile dai browser degli utenti | — |

### Import dell'immagine

L'appliance viene fornita in due formati equivalenti — scegli quello supportato dal tuo hypervisor:

- **File `.ova`** → VirtualBox (*File → Importa appliance…*) o VMware (*File → Open…*)
- **File `.qcow2`** → Proxmox (importa come disco di una nuova VM) o KVM/QEMU diretto:

  ```bash
  qemu-system-x86_64 -m 2048 -smp 2 -enable-kvm \
    -drive file=sentinelcore-<versione>-linux-x86_64.qcow2,format=qcow2 \
    -netdev user,id=net0 -device virtio-net-pci,netdev=net0
  ```

Avvia la VM.

### Primo avvio dell'appliance

**Al primo avvio di ogni copia** (ogni volta che importi o cloni una nuova appliance), un servizio automatico rigenera tutti i segreti univoci dell'istanza — password del database, chiave di firma delle sessioni, chiavi SSH dell'host, certificato TLS — così due appliance nate dalla stessa immagine non condividono mai le stesse credenziali. Questa fase richiede qualche decina di secondi e avviene una sola volta.

Al termine, le credenziali di accesso vengono stampate **sulla console della VM** e salvate nel messaggio del giorno (visibile al login SSH):

```
╔══════════════════════════════════════════════════════════════╗
║          SentinelCore — Credenziali iniziali istanza         ║
╠══════════════════════════════════════════════════════════════╣
  URL:        https://192.168.x.x
  Utente:     admin
  Password:   XxXxXxXx1234Aa1!
  CAMBIA la password al primo accesso (Impostazioni → Profilo).
╚══════════════════════════════════════════════════════════════╝
```

Annota indirizzo, utente e password: ti serviranno per il primo accesso (capitolo successivo). L'indirizzo indicato è quello assegnato via DHCP alla VM sulla rete a cui l'hai collegata.

> **Importante:** cambia la password admin **subito dopo il primo accesso**. L'account iniziale non è protetto da un cambio password obbligatorio a livello di sistema: è una buona pratica di sicurezza che spetta a te applicare.

Da qui in poi l'appliance si comporta come un'installazione normale: ad ogni riavvio successivo non rigenera più nulla.

---

## Modalità B — Pacchetto binario su un server esistente

### Requisiti

- Debian 12 o 13, installazione pulita (l'installer configura da sé PostgreSQL, nginx e gli strumenti di scansione di rete)
- Accesso `sudo`
- Connessione di rete in uscita (per installare i pacchetti di sistema necessari)

### Passi

1. Scarica il pacchetto (`sentinelcore-<versione>-linux-x86_64.tar.gz`) e verificane l'integrità, se disponi del checksum:

   ```bash
   sha256sum -c sentinelcore-<versione>-linux-x86_64.tar.gz.sha256
   ```

2. Estrai ed esegui l'installer:

   ```bash
   tar xzf sentinelcore-<versione>-linux-x86_64.tar.gz
   cd sentinelcore-<versione>-linux-x86_64
   sudo ./install.sh
   ```

   L'installer rileva automaticamente l'indirizzo IP e l'interfaccia di rete della macchina. Se hai più interfacce o vuoi forzare un nome host specifico:

   ```bash
   sudo ./install.sh --server-name 10.0.0.5 --iface ens18
   ```

3. L'installer, in autonomia:
   - installa i pacchetti di sistema necessari (PostgreSQL, nginx, nmap, arp-scan);
   - crea utente e database dedicati con password generata casualmente;
   - applica lo schema del database;
   - genera un certificato TLS auto-firmato per l'istanza e configura nginx per servire tutto in **HTTPS di default** (con redirect automatico da HTTP);
   - configura il servizio di sistema (systemd);
   - crea il primo account **admin**, stampandone le credenziali a fine installazione.

4. Al termine, annota le credenziali admin stampate a schermo e collegati all'indirizzo indicato.

> Per esporre l'istanza su Internet con un dominio reale e un certificato Let's Encrypt al posto di quello auto-firmato, consulta la documentazione tecnica `packaging/HTTPS.md` nel repository, oppure richiedila al tuo fornitore.

---

## Aggiornare un'installazione esistente

Per passare da una versione di SentinelCore alla successiva **senza perdere dati**, usa lo script `upgrade.sh` incluso in ogni nuovo pacchetto binario (funziona allo stesso modo sia per un'installazione da pacchetto, sia per un'appliance VM, sia per un'immagine qcow2):

```bash
tar xzf sentinelcore-<nuova-versione>-linux-x86_64.tar.gz
cd sentinelcore-<nuova-versione>-linux-x86_64
sudo ./upgrade.sh
```

Lo script esegue in automatico, in quest'ordine:

1. **Backup del database** (prima di qualsiasi modifica — se questo passo fallisce, l'aggiornamento si ferma e non viene applicato nulla);
2. arresto del servizio;
3. backup dei file correnti (per un ripristino automatico se il passo successivo fallisce);
4. installazione dei nuovi file (binario, frontend, migrazioni, configurazione di sistema);
5. applicazione delle modifiche al database necessarie alla nuova versione;
6. riavvio del servizio e verifica automatica che risponda correttamente.

Se qualcosa va storto durante l'applicazione delle modifiche al database, lo script **ripristina automaticamente la versione precedente** e riavvia il servizio: non resti mai con un'istanza a metà aggiornata. Il backup del database resta comunque disponibile in `/opt/sentinelsuite/sentinelcore/backups/` per un ripristino manuale in casi eccezionali.

> Non serve rieseguire `install.sh` per un aggiornamento: `install.sh` è solo per la primissima installazione.
