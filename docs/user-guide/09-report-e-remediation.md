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

Un **piano di remediation** (Amministratore) raggruppa una o più vulnerabilità e i dispositivi coinvolti in un unico obiettivo tracciabile: ha un titolo, uno stato di avanzamento, una sezione commenti per coordinare il lavoro tra le persone coinvolte, e — al completamento — una fase di verifica per confermare che il rimedio applicato abbia effettivamente funzionato (es. dopo una nuova scansione).

È lo strumento giusto quando la risoluzione di più vulnerabilità richiede un intervento coordinato (es. un aggiornamento pianificato su un gruppo di server), invece di lavorare le vulnerabilità una per una senza un contesto comune.

### Creare un piano: cosa significano i campi della sezione "Pianificazione"

- **Priorità** (P1 Critica / P2 Alta / P3 Media / P4 Bassa) — è **solo un'etichetta informativa** sul piano stesso, utile per ordinarlo/segnalarlo nella lista piani: non filtra né influenza in alcun modo quali device o vulnerabilità finiscono nel piano. Per selezionare cosa includere in base al rischio reale usa i filtri della sezione "Selezione device" (sotto), non la priorità.
- **Stato** — il ciclo di vita del piano:
  - *Bozza*: in preparazione, il team assegnato non lo vede ancora;
  - *Attivo*: comunicato al team, pronto ma non ancora iniziato;
  - *In corso*: il team ci sta lavorando (si imposta a mano);
  - *Completato*: si imposta **da solo automaticamente** quando il 100% delle vulnerabilità del piano risulta risolto — non serve chiuderlo a mano;
  - *Annullato*: piano abbandonato.
- **Team assegnato** — il team responsabile dell'esecuzione del piano (facoltativo, "Nessuno" se non ancora deciso).

Solo in fase di **creazione** (non modificabile dopo, perché i device del piano sono già fissati) puoi anche filtrare automaticamente quali device includere, nella sezione "Selezione device":

- **Solo device di questo team** — limita ai dispositivi assegnati a un team specifico;
- **Fascia di rischio** — filtra per `risk_tier` del nostro motore di prioritizzazione (Critical/High/Medium/Low/Info, capitolo 6) — **non** per la sola severity CVSS;
- **Ambito fascia di rischio** — "Questo tier e superiori" include anche le fasce più critiche di quella scelta; "Solo questo tier" seleziona esclusivamente quella fascia;
- **Solo device internet-facing** — limita ai dispositivi esposti su Internet (vedi capitolo 7 per come viene determinata l'esposizione).

## Carico di lavoro e classifiche

La dashboard **Carico di lavoro** mostra, per te e per il tuo team, quante vulnerabilità sono assegnate, quante risolte, e l'andamento nel tempo. Le classifiche di risoluzione permettono di vedere, in modo trasparente, chi sta contribuendo di più alla riduzione del rischio complessivo — pensate come stimolo collaborativo, non come strumento di controllo individuale.
