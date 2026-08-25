# 7. Rete e asset

SentinelCore distingue due percorsi distinti che è utile non confondere:

- **Network Discovery** — scopre *dispositivi* sulla rete (IP, MAC, hostname, sistema operativo, porte aperte) e li mostra come nodi di una topologia. Non genera da sola vulnerabilità: mappa "cosa c'è in rete".
- **Import scanner** (capitolo 8) — importa *vulnerabilità* trovate da uno scanner esterno o dal connettore OpenVAS, e le collega agli asset noti.

## Scansione di rete

Dalla pagina **Discovery** puoi avviare una scansione manuale immediata, oltre a quella pianificata configurabile in Impostazioni (capitolo 4). Puoi scegliere al volo tipo di scansione, timing e opzioni, oppure usare i valori di default configurati dall'amministratore.

Al termine, la mappa di **topologia di rete** mostra i dispositivi scoperti come nodi collegati, con indicazione visiva di stato (online/offline) e, se disponibili, del numero di vulnerabilità note per dispositivo.

## Host / asset

La pagina **Host** elenca tutti gli asset conosciuti (scoperti via rete o creati manualmente), con hostname, indirizzo IP, sistema operativo, tipo di dispositivo, criticità e stato. Da qui puoi:

- aprire il dettaglio di un singolo host — mostra le informazioni dell'asset (non avvia direttamente azioni sulle sue vulnerabilità: quelle si gestiscono dalla pagina Vulnerabilità, filtrando per quell'asset);
- modificare in blocco più dispositivi selezionati (es. assegnare un proprietario, un livello di criticità, dei tag);
- eliminare in blocco dispositivi non più rilevanti.

### Quali campi di un host influenzano davvero il punteggio di rischio

Aprendo il dettaglio di un host trovi la scheda **"System Configuration" → "RBRE & Compliance"** (il nome resta in inglese anche con l'interfaccia in italiano). Contiene diversi campi, ma **solo tre** di questi entrano davvero nel calcolo del punteggio di rischio delle vulnerabilità di quell'host — gli altri sono informativi/organizzativi. Sapere quali sono ti permette di alzare o abbassare consapevolmente il rischio calcolato per un host, invece di scoprirlo per tentativi:

| Campo (nome in UI) | Valori | Effetto sul punteggio |
|---|---|---|
| **Business Criticality** | Mission Critical / Core Business / Supporto / Lab-Test | È il fattore con più peso: da solo può valere fino a 15 punti su 100. "Mission Critical" segnala un sistema il cui fermo blocca il business (es. gateway di pagamento, autenticazione, infrastruttura core); "Lab/Test" un ambiente di sviluppo il cui compromesso ha impatto reale minimo. |
| **Exposure Level** | Internet Facing / DMZ / Internal / Segmented | Fino a 12 punti. "Internet Facing" (o un IP pubblico rilevato automaticamente sull'host) porta il massimo; "Segmented" (rete isolata) porta il minimo — un attaccante deve prima superare un altro livello di rete per raggiungerlo. |
| **Data Classification** *(oppure il flag* **Data Processor (GDPR)** *acceso)* | Public / Internal / Sensitive / Critical | +5 punti fissi se il valore è "Sensitive" o "Critical", oppure se il flag "Data Processor (GDPR)" è acceso — segnala che l'host tratta dati personali/sensibili, indipendentemente dalla classificazione testuale. |

**Non entrano invece nel calcolo** (anche se si trovano nella stessa scheda e potrebbero sembrare correlati): "Criticality (legacy)", Device Use Case, Remediation Difficulty, gli switch "Internet Facing"/"Has Public IP"/"Patch Available", e il campo libero "Deployment Impact". Sono utili per organizzazione e reportistica interna, ma oggi non spostano il punteggio di rischio di una singola unità.

> Un IP pubblico viene comunque rilevato **automaticamente** dal sistema guardando l'indirizzo della vulnerabilità stessa (tutto ciò che non rientra nei range privati RFC 1918/loopback/link-local) — non serve marcare nulla a mano perché questa parte funzioni; è "Exposure Level" il campo che aggiunge un giudizio più fine (es. DMZ vs Internet Facing) sopra a quel rilevamento automatico.

Il resto della scheda **Host** (proprietario, note, tag, tipo dispositivo) resta comunque utile per organizzazione interna, filtri e ricerca, anche se non influenza il punteggio.

> Per policy predefinita, un utente semplice non modifica questi campi direttamente ma propone una modifica che un admin/team leader approva — vedi "Override permessi utente" nel capitolo 4 per attivare la modifica diretta.
