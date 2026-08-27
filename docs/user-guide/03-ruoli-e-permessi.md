# 3. Ruoli e permessi

SentinelCore ha tre ruoli. Un utente ne ha esattamente uno, assegnato da un amministratore.

## Amministratore (`admin`)

Controllo completo della piattaforma. Oltre a tutto ciò che possono fare Team Leader e Utente, l'Amministratore è l'unico che può:

- creare, modificare ed eliminare vulnerabilità, asset e team;
- assegnare vulnerabilità a team/utenti (singolarmente o in blocco);
- gestire gli utenti (creazione, blocco, sessioni attive, ruoli);
- definire le regole di assegnazione automatica e la politica generale (automatica/manuale);
- definire le regole di notifica e i canali di invio;
- importare file da scanner esterni;
- gestire i piani di remediation;
- gestire il ciclo di vita dell'accettazione del rischio (risk acceptance: approvare, rifiutare, rinnovare);
- registrare e verificare le risoluzioni;
- gestire i plugin (inclusa la configurazione del connettore OpenVAS);
- configurare l'integrazione JIRA e i webhook SOAR;
- accedere al log di audit;
- modificare tutte le **Impostazioni** di sistema (rete, sicurezza, notifiche, MCP, ecc.);
- creare chiavi API con permessi di **scrittura** per il server MCP (vedi capitolo 4).

## Team Leader (`team_leader`)

Un coordinatore con visibilità e alcune capacità di gestione più ampie di un Utente semplice, ma senza i poteri di sistema di un Amministratore:

- vede e naviga le sezioni **Piani di remediation**, **Import scanner** e **Report**, non visibili a un Utente semplice;
- vede e naviga **Team** e **Utenti** — in particolare può modificare email, password e competenze (skill) dei membri del **proprio** team;
- per il resto ha le stesse capacità di un Utente (vedi sotto).

## Utente (`user`)

Il ruolo operativo di base: un analista che lavora sulle vulnerabilità assegnate a sé o al proprio team.

Un Utente può:

- vedere vulnerabilità, asset, topologia di rete, team e piani condivisi;
- avviare scansioni di rete, modificare i dispositivi scoperti, assegnarli in blocco;
- commentare e menzionare colleghi (`@utente`) su vulnerabilità, asset e piani;
- generare, scaricare e ricevere via email i report a cui ha accesso;
- gestire il proprio profilo, il 2FA, le proprie chiavi API e le proprie sessioni attive;
- consultare il proprio carico di lavoro, le proprie statistiche di risoluzione e le classifiche.

Un Utente **non** può creare/modificare/eliminare vulnerabilità o asset, assegnare lavoro ad altri, gestire team o utenti, importare scanner, o accedere alle Impostazioni di sistema.

## Riepilogo rapido

| Capacità | Utente | Team Leader | Amministratore |
|---|:--:|:--:|:--:|
| Visualizzare vulnerabilità, asset, topologia, team, report | ✅ | ✅ | ✅ |
| Avviare scansioni di rete, modificare/assegnare dispositivi | ✅ | ✅ | ✅ |
| Commentare, menzionare, gestire il proprio profilo/2FA/sessioni | ✅ | ✅ | ✅ |
| Vedere Piani di remediation, Import scanner, Report nel menu | ❌ | ✅ | ✅ |
| Modificare email/password/skill dei membri del proprio team | ❌ | ✅ (solo il proprio team) | ✅ (tutti) |
| Creare/modificare/eliminare vulnerabilità e asset | ❌ | ❌ | ✅ |
| Assegnare vulnerabilità a team/utenti | ❌ | ❌ | ✅ |
| Creare/eliminare team, gestire regole di assegnazione | ❌ | ❌ | ✅ |
| Gestire utenti (creazione, blocco, ruoli) | ❌ | ❌ | ✅ |
| Importare file da scanner esterni | ❌ | ❌ | ✅ |
| Gestire piani di remediation, risk acceptance | ❌ | ❌ | ✅ |
| Gestire plugin, connettore OpenVAS, JIRA, webhook SOAR | ❌ | ❌ | ✅ |
| Accedere al log di audit e alle Impostazioni di sistema | ❌ | ❌ | ✅ |

## Ruolo all'interno di un team

Indipendentemente dal ruolo di piattaforma, ogni appartenenza a un team ha un proprio ruolo interno — **leader** o **contributor** — assegnabile da un amministratore o da un team leader dalla pagina **Team**. Questo ruolo è indipendente dal ruolo di piattaforma: un Utente può essere "leader" all'interno del proprio team, senza per questo diventare un `team_leader` di piattaforma.

## Permessi granulari (uso avanzato)

Oltre ai tre ruoli, un amministratore può concedere **permessi puntuali** a un singolo utente su una risorsa specifica (con scadenza opzionale), per gestire eccezioni senza dover cambiare il ruolo di base della persona. È una funzionalità pensata per casi particolari, non per la gestione quotidiana dei permessi.
