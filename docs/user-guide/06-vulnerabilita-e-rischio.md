# 6. Vulnerabilità e punteggio di rischio

## Dashboard

La pagina iniziale (**Dashboard**) mostra un riepilogo dello stato generale: conteggi per severità, andamento nel tempo, e una tabella delle vulnerabilità critiche/alte più recenti — ordinata per **punteggio di rischio**, non per il semplice punteggio CVSS dello scanner (vedi sotto perché la differenza conta).

### Il grafico "Vulnerability Trend" e il dettaglio di un giorno

Ogni colonna del grafico rappresenta le vulnerabilità **aperte in quel giorno** (scoperte entro quel giorno e non ancora risolte alla sua fine), negli ultimi 30 giorni. **Cliccando su una colonna** si apre al centro dello schermo un pannello con il dettaglio di quel giorno, e la colonna scelta cambia colore:

- **Titolo** — la data, con due frecce agli estremi (sinistra e destra) per passare al giorno precedente o successivo senza chiudere il pannello; funzionano anche le frecce ← → della tastiera, e Esc chiude;
- **A sinistra (circa metà pannello)** — un grafico a rosa per severity: tutte le fette hanno lo stesso angolo e la **lunghezza** dice quante vulnerabilità ci sono; il totale è scritto al centro, il numero dentro ogni fetta, e ogni fetta ha la sua etichetta esterna con nome, numero e percentuale, collegata da una linea;
- **A destra** — tre numeri (vulnerabilità aperte quel giorno con la differenza rispetto al giorno prima, nuove, risolte), le **vulnerabilità più critiche** di quel giorno e gli **host più esposti**. Cliccando una vulnerabilità o un host si apre la sua pagina di dettaglio; in fondo i pulsanti *Tutte le vulnerabilità* e *Tutti gli host* portano agli elenchi.

### La colonna "Trend" delle vulnerabilità recenti

Nella tabella delle vulnerabilità critiche/alte (e nell'elenco Vulnerabilità) la colonna **Trend** non è un grafico: è un indicatore basato su dati reali, perché per la singola vulnerabilità non esiste una serie storica. Mostra una freccia rossa verso l'alto se la vulnerabilità è stata **riaperta** (con il numero di volte), una freccia verde verso il basso se è **risolta**, una freccia blu se è **in corso**, un trattino se è **stabile**.

## Il punteggio di rischio: perché non basta il CVSS

Ogni vulnerabilità importata porta con sé un punteggio CVSS (la "gravità tecnica" assegnata dallo scanner o dal database CVE), ma SentinelCore calcola per ciascuna anche un **punteggio di rischio** proprietario, su scala 0–100, che combina:

- il punteggio **CVSS** di base;
- la probabilità reale di sfruttamento (**EPSS**, aggiornata quotidianamente);
- l'**impatto di business** dell'asset coinvolto (quanto è critico quel sistema per l'organizzazione);
- l'**esposizione** dell'asset (è raggiungibile da Internet? è su una rete interna segmentata?);
- la **disponibilità di exploit** noti e pubblici.

Sopra a questo calcolo composito esistono override che forzano il punteggio verso l'alto indipendentemente dal resto, per tre categorie che meritano sempre priorità assoluta: vulnerabilità **zero-day**, CVE **sfruttate attivamente da campagne ransomware** e CVE presenti nel catalogo **CISA KEV** (Known Exploited Vulnerabilities — sfruttate attivamente "in the wild").

Il punteggio di rischio determina anche il **livello di rischio** (risk tier) della vulnerabilità — Critical / High / Medium / Low — a cui è agganciata la scadenza SLA di rimedio:

| Livello di rischio | Scadenza (SLA) |
|---|---|
| Critical | 1 giorno |
| High | 7 giorni |
| Medium | 30 giorni |
| Low | 90 giorni |

## Elenco vulnerabilità

La pagina **Vulnerabilità** mostra tutte le vulnerabilità note, filtrabili per severità, stato, team/utente assegnato, asset e testo libero. Per ogni riga sono visibili severità, punteggio di rischio, stato e assegnazione corrente.

Con il **tasto destro** su una riga (o su più righe selezionate) trovi le azioni rapide, tra cui **Aggiungi al piano di remediation (bozza)**: apre l'elenco dei piani ancora in bozza e aggiunge a quello scelto gli host delle vulnerabilità selezionate (vedi capitolo 9).

### Stati di una vulnerabilità

- **Open** — scoperta, non ancora in lavorazione;
- **In progress** — qualcuno la sta lavorando;
- **Resolved** — risolta;
- **Closed** — chiusa (dopo verifica, se prevista dal piano di remediation);
- **Reopened** — era risolta/chiusa ma è stata rilevata di nuovo in una scansione successiva: viene segnalata separatamente dalle "open" ordinarie perché indica una regressione, non solo un ritardo.

### Assegnazione

Un Amministratore può assegnare una vulnerabilità (o più in blocco) a un team o a un utente specifico. In alternativa, se la policy "Assegnazione vulnerabilità" (capitolo 4) è impostata su **automatica**, il sistema la assegna da solo dopo il ritardo configurato, in base alle competenze di team/utenti disponibili.

Ogni utente trova le vulnerabilità assegnate a sé (direttamente o tramite il proprio team) nella voce di menu **Le mie vulnerabilità**, e il proprio carico di lavoro complessivo — insieme a statistiche di risoluzione e classifiche — nella dashboard dedicata al carico di lavoro.

## Dettaglio di una vulnerabilità

Aprendo una vulnerabilità trovi: descrizione tecnica, riferimenti CVE/CWE, cronologia degli eventi (timeline), e una sezione **commenti** dove puoi discutere il caso con il team:

- le risposte si possono annidare a **qualsiasi livello** (non solo due); oltre una certa profondità il rientro smette di crescere, così il thread resta leggibile;
- scrivendo `@` compare l'**autocompletamento** con tutti gli utenti della piattaforma: scegline uno per menzionarlo. **Solo le persone menzionate** ricevono la notifica in-app, non l'intero team;
- l'etichetta **Internal** è solo un'indicazione ("nota interna"): non limita chi può leggere il commento.

La **timeline** della vulnerabilità (cronologia degli eventi) è leggibile da ogni utente autenticato, indipendentemente dal ruolo o dal team.

## Accettazione del rischio (risk acceptance)

Per vulnerabilità che, per motivi tecnici o di business, si decide consapevolmente di **non risolvere** (o non nell'immediato), un Amministratore può avviare un percorso di accettazione del rischio: la decisione viene approvata, motivata, e resta soggetta a rinnovo/revisione periodica invece di restare silenziosamente "aperta" a tempo indefinito.

> Il punteggio di rischio descritto sopra è il dato usato ovunque nell'applicazione compaia una nozione di "priorità" o "rischio" — dashboard, tabelle, e soprattutto i report (capitolo 9): il CVSS grezzo resta visibile solo come dettaglio tecnico della singola vulnerabilità, mai come criterio di ordinamento o di somma aggregata.
