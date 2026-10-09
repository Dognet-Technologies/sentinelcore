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

Un **piano di remediation** (creato e modificato da Team Leader e Amministratori; l'eliminazione è riservata all'Amministratore) è un **ordine di lavoro**: un amministratore decide che un insieme preciso di vulnerabilità va sistemato e lo affida a un team. Il criterio non è per forza il rischio: può essere "tutte le vulnerabilità critiche", ma anche "quelle di rischio basso su questa rete perché siamo sotto audit". Per questo il piano contiene **vulnerabilità scelte con precisione**, non host interi: gli host del piano sono quelli delle sue vulnerabilità, e **una vulnerabilità nuova comparsa su un host del piano non ci entra da sola**. L'avanzamento è la percentuale di vulnerabilità del piano realmente risolte o chiuse (la colonna *Progress* della lista, ad esempio "50% (4/8)"). Ha un titolo, uno stato, una sezione commenti per coordinare il lavoro e, al completamento, una fase di verifica per confermare che il rimedio abbia funzionato (es. dopo una nuova scansione).

È lo strumento giusto quando la risoluzione di più vulnerabilità richiede un intervento coordinato (es. un aggiornamento pianificato su un gruppo di server), invece di lavorare le vulnerabilità una per una senza un contesto comune.

### Il ciclo di vita di un piano

- **Bozza** — in preparazione: il team assegnato **non lo vede e non riceve notifiche**. È l'unico stato in cui si può cambiare il contenuto del piano.
- **Attivo** — comunicato al team (qui parte la notifica), pronto ma non ancora iniziato. Da ora l'elenco degli host è bloccato.
- **In corso** — il team ci sta lavorando (si imposta a mano).
- **Completato** — passa **da solo e subito**, nello stesso istante in cui l'ultima vulnerabilità del piano viene risolta o chiusa: non serve chiuderlo a mano e non c'è da aspettare. Anche gli host del piano risultano completati (un host si completa già prima, quando le sue vulnerabilità sono tutte risolte), la lista dei piani si aggiorna da sola e il team assegnato riceve l'avviso di completamento (email, Slack, Telegram secondo le sue impostazioni) entro un minuto. Una bozza non si chiude mai da sola, e un piano concluso non si riapre se una vulnerabilità viene riaperta in seguito.
- **Annullato** — piano abbandonato.

### Creare un piano

Da **Piani di remediation → Nuovo piano**. Il modulo ha queste sezioni:

- **Informazioni generali** — nome e descrizione.
- **Pianificazione**:
  - **Priorità** (P1 Critica … P4 Bassa) — è **solo un'etichetta informativa** sul piano, utile per ordinarlo e segnalarlo nella lista: non influenza quali vulnerabilità finiscono nel piano;
  - **Stato** — vedi sopra (un piano nuovo parte in bozza);
  - **Data scadenza** e **Team assegnato** — facoltativi.
- **Contenuto del piano** — dove scegli quali vulnerabilità includere (sotto).

### Scegliere il contenuto del piano

Nella sezione **Contenuto del piano** vedi in alto le vulnerabilità già incluse, raggruppate per host (con il totale "N vulnerabilità su M host"), e sotto il riquadro **Cerca vulnerabilità da aggiungere**. I criteri sono tutti facoltativi e **si combinano** (tutti insieme devono essere veri; più valori dello stesso criterio sono alternativi):

- **Testo libero** — titolo, CVE, nome host o IP;
- **Reti / IP** — uno o più CIDR o IP, per esempio `10.0.1.0/24` (le reti non valide vengono segnalate);
- **CVE** — una o più;
- **Team proprietario dell'host** ed **Esposizione** (esposti su internet / solo interni);
- **Tipo di host** — server, firewall, database…;
- **Livello di rischio** del nostro motore di prioritizzazione (Critical…Info, capitolo 6) e **Gravità** dello scanner;
- **Solo sfruttate (catalogo KEV)**.

Premi **Cerca**: compaiono i totali ("N vulnerabilità su M host corrispondono") e i risultati raggruppati per host. Da lì:

- spunta le singole vulnerabilità (o l'intestazione di un host per tutte le sue) e premi **Aggiungi N selezionate**;
- oppure **Aggiungi tutte (N)** per includere tutto ciò che la ricerca ha trovato;
- oppure, sull'**intestazione di un host** (menu ⋮ o tasto destro), **Aggiungi tutte le vulnerabilità dell'asset** o **Aggiungi quelle di rischio X o superiore**.

Una ricerca senza criteri non è ammessa: non significa "tutto". Le vulnerabilità già nel piano non vengono riproposte, e con più di 500 risultati l'elenco mostra solo i primi (i totali restano esatti): in modifica **Aggiungi tutte** le comprende comunque tutte, in creazione conviene restringere i criteri.

Per **togliere** una vulnerabilità usa la X sulla sua riga, per togliere un intero host la X sull'intestazione, **Svuota il piano** per ricominciare.

- Creando un nuovo piano, le vulnerabilità scelte vengono salvate insieme al piano (una nota sotto l'elenco lo ricorda).
- Modificando un piano **in bozza**, aggiunta e rimozione sono **immediate**.
- Su un piano che **non è più in bozza** il contenuto è in sola lettura, con la nota *"Il contenuto di un piano si può cambiare solo finché è in bozza"* (anche il server rifiuta la modifica).
- I piani creati prima di questa versione conservano le vulnerabilità che coprivano di fatto (tutte quelle dei loro host al momento dell'aggiornamento); da lì in poi non assorbono più vulnerabilità nuove.

### Aggiungere a un piano in bozza da altre pagine

Dalle pagine **Host** e **Vulnerabilità**, con il **tasto destro**, trovi la voce **Aggiungi al piano di remediation (bozza)**: si apre l'elenco dei piani **in bozza** (se non ce ne sono, la voce dice "Nessun piano in bozza"). Scegli il piano e l'azione si applica a **tutta la selezione** (più righe selezionate) oppure alla riga sotto il puntatore.

- Da **Host** si aggiungono **tutte le vulnerabilità aperte** degli host selezionati.
- Da **Vulnerabilità** si aggiungono **solo le vulnerabilità selezionate**, non quelle del loro host.
- Un messaggio riassume l'esito, ad esempio *"3 vulnerabilità aggiunte al piano «Patch Q4» · 1 già presenti"*. Le vulnerabilità che non hanno un dispositivo di rete collegato non possono stare in un piano.
- La voce è disponibile a Team Leader e Amministratori.

## Carico di lavoro e classifiche

La dashboard **Carico di lavoro** mostra, per te e per il tuo team, quante vulnerabilità sono assegnate, quante risolte, e l'andamento nel tempo. Le classifiche di risoluzione permettono di vedere, in modo trasparente, chi sta contribuendo di più alla riduzione del rischio complessivo — pensate come stimolo collaborativo, non come strumento di controllo individuale.
