# Introduzione

## Cos'è SentinelCore

SentinelCore è una piattaforma di **vulnerability management** pensata per team di sicurezza interni. Il suo compito è raccogliere in un unico posto tutte le vulnerabilità della tua infrastruttura — scoperte dalla scansione di rete integrata o importate da scanner di terze parti — assegnare a ciascuna un **punteggio di rischio reale** (non solo il punteggio CVSS "di targa"), instradarle alle persone giuste, tracciarne la risoluzione rispetto a scadenze (SLA) e produrre i report che servono per audit e conformità.

Tutto il prodotto ruota attorno a un unico flusso operativo:

```
scopri → importa → valuta il rischio → assegna → risolvi → verifica → rendiconta
```

Ogni fase di questo flusso corrisponde a una sezione precisa dell'interfaccia, descritta nei capitoli seguenti.

## A chi si rivolge questo manuale

Questo manuale è pensato per due tipi di lettori:

- **Chi installa e amministra** SentinelCore (un amministratore di sistema o un responsabile sicurezza) — capitoli 1–4.
- **Chi lo usa ogni giorno** per gestire vulnerabilità, team e report (analisti, team leader) — capitoli 5 in poi.

Non è richiesta alcuna conoscenza di programmazione: SentinelCore si installa da pacchetti pronti e si usa interamente da interfaccia web.

## Cosa fa SentinelCore

- **Network Discovery** — scansione di rete integrata (basata su nmap) con profili configurabili, pianificazione ricorrente e mappa di topologia degli host scoperti.
- **Importazione da scanner esterni** — legge i risultati di 10 scanner di terze parti (Qualys, Nessus, Burp Suite, OpenVAS/GVM, Nexpose/InsightVM, OWASP ZAP, Nmap, Nikto, Trivy, Grype), normalizza la severità, deduplica i risultati e li collega agli asset.
- **Connettore OpenVAS diretto** — un connettore integrato interroga periodicamente un'istanza GVM/OpenVAS e importa automaticamente i report completati, senza bisogno di esportare file a mano.
- **Punteggio di rischio** — un punteggio composito 0–100 che combina CVSS, probabilità di sfruttamento reale (EPSS), impatto di business, esposizione dell'asset e disponibilità di exploit noti, con override automatici per zero-day, CVE sfruttate da ransomware e vulnerabilità attivamente sfruttate (catalogo CISA KEV).
- **SLA e scadenze** — ogni livello di rischio ha una scadenza di rimedio (Critical 1 giorno, High 7 giorni, Medium 30 giorni, Low 90 giorni); il sistema segnala automaticamente gli sforamenti.
- **Assegnazione** — manuale (a team o utente) oppure automatica tramite regole basate su competenze (skill) e bilanciamento del carico.
- **Piani di remediation** — raggruppano vulnerabilità e dispositivi in piani eseguibili, con stato di avanzamento, commenti e verifica finale.
- **Collaborazione** — commenti con menzioni (`@utente`), notifiche in-app, classifiche di risoluzione per utenti e team.
- **Notifiche** — motore di regole (condizioni, priorità, throttling, orari di silenzio) che invia avvisi via email, Slack e Telegram.
- **Integrazioni** — sincronizzazione bidirezionale con JIRA, arricchimento CVE da NVD, aggiornamento giornaliero EPSS, webhook SOAR in uscita.
- **Reportistica** — report di vulnerabilità (PDF/CSV/JSON/XML), report di gestione, dashboard esecutiva, mappe di calore tecniche.
- **Sicurezza e audit** — autenticazione con cookie httpOnly, protezione CSRF, autenticazione a due fattori (TOTP), gestione sessioni con revoca da remoto, log di audit completo, permessi granulari per utente.
- **Server MCP** — un'interfaccia programmatica (Model Context Protocol) che permette ad agenti AI autorizzati di consultare e, se abilitato, agire su vulnerabilità e rischio — vedi il capitolo dedicato alla configurazione.

## Cosa NON fa (per evitare aspettative sbagliate)

- **Non è uno scanner di vulnerabilità** in senso stretto: a parte la scoperta di rete/porte basata su nmap, SentinelCore non rileva da solo le vulnerabilità — le riceve da scanner esterni o dal connettore OpenVAS.
- **Non è multi-tenant**: un'installazione serve un'unica organizzazione.
- **Non ha alta affidabilità/clustering integrati**: è pensato per un singolo host con un'istanza PostgreSQL.
- **Non richiede né installa agenti** sugli endpoint monitorati: la visibilità viene dalle scansioni di rete e dai dati importati dagli scanner.
- **Non fa patching automatico su larga scala**: i piani di remediation tracciano il lavoro, non lo eseguono al posto tuo.
- **Non ha ancora LDAP/SSO integrato**: l'autenticazione è locale (username/password + 2FA opzionale).

## Come è organizzato questo manuale

| Capitolo | Contenuto |
|---|---|
| [1 — Installazione](01-installazione.md) | Le due modalità di distribuzione (VM pronta all'uso, pacchetto binario), requisiti, primo avvio |
| [2 — Primo accesso](02-primo-accesso.md) | Login iniziale, cambio password, tour rapido dell'interfaccia |
| [3 — Ruoli e permessi](03-ruoli-e-permessi.md) | I tre ruoli (Amministratore, Team Leader, Utente) e cosa può fare ciascuno |
| [4 — Configurazione](04-configurazione.md) | Tutte le sezioni di Impostazioni: preferenze, notifiche, email, sicurezza, MCP, rete, e altro |
| [5 — Team e utenti](05-team-e-utenti.md) | Creare team, aggiungere membri, gestire utenti e competenze |
| [6 — Vulnerabilità e rischio](06-vulnerabilita-e-rischio.md) | Dashboard, elenco vulnerabilità, punteggio di rischio, stati, assegnazione |
| [7 — Rete e asset](07-rete-e-asset.md) | Scansione di rete, topologia, gestione host |
| [8 — Scanner e integrazioni](08-scanner-e-integrazioni.md) | Importazione da scanner esterni, connettore OpenVAS, JIRA, notifiche |
| [9 — Report e piani di remediation](09-report-e-remediation.md) | Generare report, cronologia, piani di remediation, carico di lavoro |
| [10 — Domande frequenti](10-domande-frequenti.md) | Problemi comuni e loro soluzione |
