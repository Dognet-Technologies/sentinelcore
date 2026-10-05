# 9. Report e piani di remediation

## Generare un report

Dalla pagina **Report → Nuovo report** (Team Leader e Amministratore) puoi generare un **report di gestione** per un intervallo di date, opzionalmente filtrato per team e/o singolo asset. Il report che ne risulta include diverse sezioni:

- **Riepilogo esecutivo** — conteggi di vulnerabilità totali, nuove, risolte, aperte, in lavorazione, riaperte nel periodo, rischio eliminato e rischio residuo;
- **Metriche di gestione** — tempo medio di risoluzione (MTTR) per livello di rischio, rispetto delle SLA, distribuzione per anzianità delle vulnerabilità ancora aperte;
- **Analisi del rischio** — le vulnerabilità aperte più critiche e quelle risolte più rilevanti nel periodo;
- **Performance dei team** — confronto tra team su volumi e tempi di risoluzione;
- **Dettaglio vulnerabilità** — elenco puntuale delle vulnerabilità aperte e in lavorazione.

Quando generi un report filtrato per un team specifico, **tutte** le sezioni rispettano quel filtro: vedrai solo dati relativi a quel team, non all'intera organizzazione.

> **Importante**: in ogni report, ovunque compaia un valore di "rischio" — rischio eliminato, rischio residuo, la colonna nelle tabelle di dettaglio vulnerabilità, il rischio eliminato per team — il dato mostrato è sempre il **punteggio del motore di prioritizzazione** (risk score/tier, vedi capitolo 6), non il semplice punteggio CVSS. Il CVSS resta visibile come informazione tecnica altrove (dettaglio della singola vulnerabilità), ma non è mai il criterio con cui i report ordinano o sommano il rischio.

## Cronologia report

**Report → Cronologia** elenca tutti i report generati in precedenza, con possibilità di riaprirli, scaricarli o eliminarli (in blocco, se necessario).

## Piani di remediation

Un **piano di remediation** (creato e modificato da Team Leader e Amministratori; l'eliminazione è riservata all'Amministratore) raggruppa i **dispositivi (host)** da sistemare in un unico obiettivo tracciabile. Un piano contiene host, non singole vulnerabilità: il piano copre **tutte le vulnerabilità di ciascun host incluso**, e il suo avanzamento è la percentuale di quelle realmente risolte o chiuse (la colonna *Progress* della lista, ad esempio "50% (4/8)"). Ha un titolo, uno stato, una sezione commenti per coordinare il lavoro e, al completamento, una fase di verifica per confermare che il rimedio abbia funzionato (es. dopo una nuova scansione).

È lo strumento giusto quando la risoluzione di più vulnerabilità richiede un intervento coordinato (es. un aggiornamento pianificato su un gruppo di server), invece di lavorare le vulnerabilità una per una senza un contesto comune.

### Il ciclo di vita di un piano

- **Bozza** — in preparazione: il team assegnato **non lo vede e non riceve notifiche**. È l'unico stato in cui si possono cambiare gli host del piano.
- **Attivo** — comunicato al team (qui parte la notifica), pronto ma non ancora iniziato. Da ora l'elenco degli host è bloccato.
- **In corso** — il team ci sta lavorando (si imposta a mano).
- **Completato** — passa **da solo e subito**, nello stesso istante in cui l'ultima vulnerabilità del piano viene risolta o chiusa: non serve chiuderlo a mano e non c'è da aspettare. Anche gli host del piano risultano completati (un host si completa già prima, quando le sue vulnerabilità sono tutte risolte), la lista dei piani si aggiorna da sola e il team assegnato riceve l'avviso di completamento (email, Slack, Telegram secondo le sue impostazioni) entro un minuto. Una bozza non si chiude mai da sola, e un piano concluso non si riapre se una vulnerabilità viene riaperta in seguito.
- **Annullato** — piano abbandonato.

### Creare un piano

Da **Piani di remediation → Nuovo piano**. Il modulo ha queste sezioni:

- **Informazioni generali** — nome e descrizione.
- **Pianificazione**:
  - **Priorità** (P1 Critica … P4 Bassa) — è **solo un'etichetta informativa** sul piano, utile per ordinarlo e segnalarlo nella lista: non filtra né influenza quali host finiscono nel piano;
  - **Stato** — vedi sopra (un piano nuovo parte in bozza);
  - **Data scadenza** e **Team assegnato** — facoltativi.
- **Host del piano** — dove scegli quali host includere (sotto).
- **Aggiungi per filtro (facoltativo)** — scorciatoia per aggiungere molti host in una volta, solo alla creazione.

### Scegliere gli host del piano

Nella sezione **Host del piano** vedi in alto l'elenco degli host già inclusi — ciascuno con il numero di vulnerabilità critiche/alte e il punteggio di priorità — e sotto il selettore **Aggiungi host**:

1. cerca per **nome o indirizzo IP** (gli host sono ordinati dal più a rischio);
2. spunta uno o più host, oppure la casella **Tutti i risultati (N)** per selezionare tutto ciò che la ricerca mostra;
3. premi **Aggiungi N al piano**.

Per **togliere** un host usa la X sulla sua riga; **Togli N selezionati** svuota l'elenco. Gli host già nel piano non vengono riproposti nel selettore.

- Creando un nuovo piano, gli host scelti vengono salvati insieme al piano (una nota sotto l'elenco lo ricorda).
- Modificando un piano **in bozza**, aggiunta e rimozione sono **immediate**.
- Su un piano che **non è più in bozza** l'elenco è in sola lettura, con la nota *"Gli host di un piano si possono cambiare solo finché è in bozza"* (anche il server rifiuta la modifica).

### Aggiungere host o vulnerabilità a un piano in bozza da altre pagine

Dalle pagine **Host** e **Vulnerabilità**, con il **tasto destro**, trovi la voce **Aggiungi al piano di remediation (bozza)**: si apre l'elenco dei piani **in bozza** (se non ce ne sono, la voce dice "Nessun piano in bozza"). Scegli il piano e l'azione si applica a **tutta la selezione** (più righe selezionate) oppure alla riga sotto il puntatore.

- Da **Host** si aggiungono gli host selezionati.
- Da **Vulnerabilità** si aggiunge **l'host di ciascuna vulnerabilità** selezionata, e il piano coprirà tutte le vulnerabilità di quell'host.
- Un messaggio riassume l'esito, ad esempio *"3 host aggiunti al piano «Patch Q4» · 1 già presenti · 2 senza dispositivo di rete (non inseribili)"*. Gli asset e le vulnerabilità che non hanno un dispositivo di rete collegato non possono stare in un piano e vengono segnalati così.
- La voce è disponibile a Team Leader e Amministratori.

### La selezione per filtro (solo alla creazione)

Nella sezione **Aggiungi per filtro** puoi far includere automaticamente i dispositivi che corrispondono a:

- **Solo device di questo team** — limita ai dispositivi assegnati a un team specifico;
- **Fascia di rischio** — filtra per `risk_tier` del nostro motore di prioritizzazione (Critical/High/Medium/Low/Info, capitolo 6) — **non** per la sola severity CVSS;
- **Ambito fascia di rischio** — "Questo tier e superiori" include anche le fasce più critiche di quella scelta; "Solo questo tier" seleziona esclusivamente quella fascia;
- **Solo device internet-facing** — limita ai dispositivi con Exposure Level *Internet Facing* (vedi capitolo 7).

Gli host trovati dal filtro si sommano a quelli scelti a mano.

## Carico di lavoro e classifiche

La dashboard **Carico di lavoro** mostra, per te e per il tuo team, quante vulnerabilità sono assegnate, quante risolte, e l'andamento nel tempo. Le classifiche di risoluzione permettono di vedere, in modo trasparente, chi sta contribuendo di più alla riduzione del rischio complessivo — pensate come stimolo collaborativo, non come strumento di controllo individuale.
