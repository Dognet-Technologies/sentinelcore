# 7. Rete e asset

SentinelCore distingue due percorsi distinti che è utile non confondere:

- **Network Discovery** — scopre *dispositivi* sulla rete (IP, MAC, hostname, sistema operativo, porte aperte) e li mostra come nodi di una topologia. Non genera da sola vulnerabilità: mappa "cosa c'è in rete".
- **Import scanner** (capitolo 8) — importa *vulnerabilità* trovate da uno scanner esterno o dal connettore OpenVAS, e le collega agli asset noti.

## Scansione di rete

Dalla pagina **Discovery** puoi avviare una scansione manuale immediata, oltre a quella pianificata configurabile in Impostazioni (capitolo 4). Puoi scegliere al volo tipo di scansione, timing e opzioni, oppure usare i valori di default configurati dall'amministratore.

Al termine, la mappa di **topologia di rete** mostra i dispositivi scoperti come nodi, con indicazione visiva di stato (online/offline) e del numero di vulnerabilità note per dispositivo.

## La mappa di topologia

La pagina **Topologia di rete** è una mappa interattiva dei dispositivi. Team Leader e Amministratori dispongono di tutti i comandi qui sotto; gli Utenti consultano la mappa (zoom, scorrimento trascinando lo sfondo, dettaglio degli host). La disposizione salvata è **una sola, condivisa da tutti**.

### Muoversi e selezionare

| Azione | Come |
|---|---|
| Spostare un host | trascinalo; se fa parte di una selezione si muove **l'intera selezione**, mantenendo le distanze |
| Selezionare più host | trascina un riquadro sullo sfondo vuoto, oppure `Ctrl`+clic sui singoli host; `Esc` annulla la selezione |
| Zoom | `Ctrl`+rotellina (centrato sul puntatore) o i pulsanti lente nella barra |
| Scorrere la mappa | tasto centrale del mouse trascinando (chi può solo consultare la mappa scorre trascinando lo sfondo) |
| Inquadrare tutto | pulsante **Fit**: adatta zoom e posizione a tutto ciò che è visibile nella finestra, senza ingrandire troppo |
| Salvare la disposizione | pulsante **Salva** nella barra: si accende quando c'è qualcosa da salvare |
| Schermo intero | pulsante in alto a destra; menu e finestre restano visibili anche a schermo intero |

I nodi non possono finire sotto l'intestazione o i pannelli che stanno sopra la mappa: c'è un'area sicura in alto e a sinistra, e un host trascinato si ferma al bordo. Le disposizioni salvate in versioni precedenti che avevano nodi troppo in alto vengono abbassate automaticamente all'apertura, senza segnarle come modificate.

Con il **tasto destro** su uno o più host si apre il menu dei dispositivi: dettaglio, **nascondi icona** (l'host resta nel sistema, sparisce solo dalla mappa; il pulsante con l'occhio li mostra di nuovo), **colore** del nodo, assegnazione e altre azioni.

### Le tre viste

Il selettore in alto cambia la disposizione:

- **Subnet Grid** — gli host sono raccolti per sottorete (`/24`) in riquadri, e **la disposizione è quella salvata**;
- **Hierarchical** — a livelli: router e firewall in alto, poi switch, server ed endpoint;
- **Circular Topology** — gli host su un cerchio.

Nelle viste Hierarchical e Circular gli host sono **raggruppati per sottorete**: ogni sottorete è un blocco con il suo riquadro (nella gerarchica i blocchi stanno uno accanto all'altro, a capo dopo tre; nella circolare stanno su un cerchio grande, con gli host di ciascuna su un cerchio piccolo). Il pulsante `▣` toglie o rimette il raggruppamento. È molto comodo con reti grandi, perché un gruppo si può comprimere.

Se sposti degli host in una di queste viste e salvi, la **posizione viene ricordata per quella vista**: Subnet Grid, Hierarchical e Circular (raggruppata o no) hanno ciascuna la propria disposizione e non si sovrascrivono a vicenda.

### Sottoreti: riquadri mobili e comprimibili

Il riquadro di una sottorete **segue gli host**: se ne sposti uno il riquadro si adatta. Trascinando l'**intestazione** del riquadro (la fascia con il nome della rete, ad esempio `10.10.0.0/24`) si spostano insieme tutti gli host del gruppo. Il triangolino a sinistra del nome **comprime il gruppo** in una scheda con la rete e il numero di host; cliccandolo di nuovo il gruppo si riapre. Quando due gruppi compressi sono collegati da più linee, vedi **una sola linea** con la scritta "N links", per non sovrapporre decine di tratti: per modificare le singole linee riapri i gruppi. Quali gruppi sono compressi è una preferenza personale, ricordata per ogni utente.

### Le linee di collegamento

- **Linee azzurre tratteggiate e animate** — sono i collegamenti **scoperti dagli scanner**: indicano asset che possono comunicare tra loro. Passando il mouse compare il tipo di collegamento, gli hop e la latenza. Il pulsante `⇄N` nella barra le mostra o le nasconde (se sono molte, oltre 120, restano ferme per non appesantire la mappa; se il sistema operativo è impostato per ridurre le animazioni, restano sempre ferme).
- **Linee arancioni** — sono i collegamenti **manuali**, disegnati da te: trascina il piccolo punto arancione che compare in alto a destra di un host fino a un altro host. Vanno salvate con il pulsante Salva.

Con il **tasto destro su una linea manuale** si apre un menu per personalizzarla:

| Opzione | Scelte |
|---|---|
| **Shape** (forma) | Straight (diritta), Curved (curva), 90° rounded (a gomito con angoli arrotondati) |
| **Stroke** (tratto) | Solid, Dashed (tratteggiato), Dotted (puntinato) |
| **Start / End** | forma dell'estremità: None, Arrow (freccia), Dot (punto), Diamond (rombo) |
| **Color** | sei colori |
| **Tag** | *Lateral movement* (movimento laterale: rosso, tratteggiato, animato) e *Monitored segment* (segmento monitorato: azzurro); il tag imposta colore, tratto e animazione, che puoi poi ritoccare, e scrive la dicitura sulla linea |
| **Animation** | Still (ferma) o Flowing (con scorrimento) |
| **Edit label…** | scrive un'etichetta mostrata sulla linea |
| **Delete** | elimina la linea |

Le linee si fermano al bordo degli host e sono cliccabili in una fascia più larga del tratto, per essere facili da prendere.

## Host / asset

La pagina **Host** elenca tutti gli asset conosciuti (scoperti via rete o creati manualmente), con hostname, indirizzo IP, sistema operativo, tipo di dispositivo, criticità e stato. Quando un host non ha un hostname noto (succede spesso in reti virtuali o dietro NAT, dove nessun protocollo di risoluzione risponde) il suo nome è l'indirizzo IP, mostrato **una volta sola** e senza la maschera `/32`.

Da qui puoi:

- aprire il dettaglio di un singolo host — mostra le informazioni dell'asset (non avvia direttamente azioni sulle sue vulnerabilità: quelle si gestiscono dalla pagina Vulnerabilità, filtrando per quell'asset);
- modificare in blocco più dispositivi selezionati (es. assegnare un proprietario, un livello di criticità, dei tag);
- **aggiungere gli host selezionati a un piano di remediation in bozza** (tasto destro → *Aggiungi al piano di remediation (bozza)*, vedi capitolo 9);
- eliminare in blocco dispositivi non più rilevanti.

### Il dettaglio di un host: la scheda "RBRE & Compliance"

Aprendo il dettaglio di un host, nella scheda **System Configuration** trovi **RBRE & Compliance** (RBRE = Risk-Based Remediation Engine; il nome resta in inglese anche con l'interfaccia in italiano). È divisa in riquadri, e la differenza tra l'uno e l'altro è netta:

**1. "Input del risk score"** — evidenziato, con l'etichetta **Pilota il risk score**. Contiene **solo ed esclusivamente** i dati dell'host che entrano davvero nel calcolo del punteggio di rischio delle sue vulnerabilità (insieme a CVSS, EPSS ed exploit, che sono della vulnerabilità, non dell'host). Accanto a ogni valore trovi i **punti** che porta al calcolo; in modifica, sotto il campo, vedi i punti di tutti i valori possibili:

| Campo | Valori e punti | Note |
|---|---|---|
| **Business Criticality** | Mission Critical 15 · Core Business 11 · Supporto 6 · Lab/Test 2 | È il fattore con più peso. "Mission Critical" segnala un sistema il cui fermo blocca il business; "Lab/Test" un ambiente il cui compromesso ha impatto minimo. |
| **Exposure Level** | Internet Facing 12 · DMZ 10 · Internal 5 · Segmented 0 | Quanto l'host è raggiungibile da un attaccante. |
| **Data Classification** | Public / Internal: nessun bonus · Sensitive / Critical: +5 | Segnala che l'host tratta dati sensibili. |
| **Data Processor (GDPR)** | acceso: +5 | Anch'esso segnala dati personali. **Non si somma** a Data Classification: i dati sensibili valgono +5 **una volta sola**, che a motivarli sia la classificazione, il flag, o entrambi. |
| **IP pubblico** *(sola lettura)* | Sì: esposizione al massimo (12) | Rilevato **automaticamente** dall'indirizzo (tutto ciò che non è nei range privati RFC 1918, loopback o link-local). Un IP pubblico porta l'esposizione al massimo qualunque sia l'Exposure Level; non c'è nulla da impostare a mano. |

**2. "Contesto di remediation"** e **3. "Compliance e note"** — sono **solo informativi**: Remediation Difficulty, Patch Available, Deployment Impact, Compensating Controls, Compliance Requirements, tag e note aiutano chi pianifica e assegna gli interventi e chi fa reportistica, ma **non entrano in nessun calcolo**.

> **Cosa è cambiato rispetto alle versioni precedenti.** Prima esistevano campi doppi che dicevano la stessa cosa e potevano contraddirsi (ad esempio *Criticality* e *Business Criticality*, oppure *Internet Facing* ed *Exposure Level*). Ora sono unificati: **Criticality** deriva da Business Criticality, **Internet Facing** da Exposure Level e **Has Public IP** dall'indirizzo, e non si inseriscono più a mano — servono solo a ordinare gli host nei piani di remediation. Il campo *Device Use Case*, che aveva la stessa lista del tipo di dispositivo e non influenzava nulla, non è più mostrato. Il tipo di dispositivo si sceglie nella scheda *System Information* e guida l'icona.

> Per policy predefinita, un utente semplice non modifica questi campi direttamente ma propone una modifica che un admin/team leader approva — vedi "Override permessi utente" nel capitolo 4 per attivare la modifica diretta.

### Cloni in altre reti (testing e pre-produzione)

Di solito gli host sono asset **in produzione**, ma può esistere una copia dello stesso asset in una rete di **testing** e/o di **pre-produzione**: è dove conviene provare una remediation o una modifica prima di applicarla in produzione. La scheda **Cloni in altre reti** (sotto RBRE & Compliance, con la sua matita di modifica) serve a dichiararlo:

- **Clone in rete di Testing** e **Clone in rete di Pre-produzione** sono due caselle indipendenti. Spuntandone una si abilitano i campi del clone:
  - **Host del clone** — IP, hostname o URL dell'host nell'altra rete (obbligatorio se la casella è spuntata);
  - **Rete / CIDR del clone** — facoltativo: la rete in cui sta il clone, come CIDR (es. `10.20.0.0/24`) o come nome. Di norma le reti di testing e di pre-produzione hanno indirizzamenti diversi da quella di produzione, quindi conviene indicarla;
  - **ID agent (dog_agent) sul clone** — l'identificativo dell'agent che gira su quel clone (facoltativo). Sono ammessi lettere, numeri e i simboli `. _ : -`;
  - **Allineato alla produzione** — una spunta per dichiarare esplicitamente che il clone ha le stesse versioni dei servizi e gli stessi aggiornamenti. Dovrebbe esserlo sempre, ma scriverlo dice a chi lo usa se può fidarsi del test.
- Togliendo la spunta, i dati di quel clone vengono cancellati: non restano valori vecchi dimenticati.
- Modifica e salvataggio seguono le stesse regole degli altri dati del dispositivo (Amministratore e Team Leader del team dell'host; un Utente solo con l'override di modifica diretta, vedi capitolo 4).

È un'informazione **solo organizzativa**: oggi non entra in nessun calcolo (né nel punteggio di rischio né nei piani di remediation) e non avvia nessuna azione sul clone. È predisposta perché in futuro venga **esportata verso le integrazioni tra gli host** della suite.

### Il riepilogo remediation di un host

In fondo alla stessa pagina la scheda **Remediation Summary** riguarda **solo l'host che stai guardando** (il suo nome è scritto nell'intestazione). I numeri contano i **piani di remediation che includono questo host**, escluse le bozze e i piani annullati: un piano con quattro host conta 1 su ciascuno dei quattro, quindi due host dello stesso piano mostrano lo stesso numero.

- **Piani in corso** — piani non ancora conclusi per questo host, con un link a ciascuno;
- **Piani completati** — piani in cui l'host risulta completato (tutte le sue vulnerabilità risolte);
- **Falliti o saltati**;
- **Ultima remediation conclusa su questo host** — nome del piano (con link), esito e data.
