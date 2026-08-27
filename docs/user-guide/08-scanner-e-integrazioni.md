# 8. Scanner e integrazioni

## Import da file scanner

La pagina **Import scanner** (Team Leader e Amministratore) permette di caricare il file di risultati esportato da uno scanner di terze parti. SentinelCore riconosce il formato e ne estrae le vulnerabilità, normalizzando la severità su una scala comune ed evitando duplicati quando la stessa vulnerabilità viene rilevata più volte.

Scanner supportati:

| Scanner | Formato tipico |
|---|---|
| Qualys | XML |
| Nessus | .nessus (XML) |
| Burp Suite | XML |
| OpenVAS / GVM | XML |
| Nexpose / InsightVM | XML |
| OWASP ZAP | XML/JSON |
| Nmap | XML |
| Nikto | XML/CSV |
| Trivy | JSON |
| Grype | JSON |

## Connettore OpenVAS diretto (senza esportare file a mano)

Se disponi di un'istanza OpenVAS/GVM, un Amministratore può configurarne la connessione diretta dalla pagina **Plugin**: host/porta (o socket) del servizio GMP, credenziali, intervallo di polling e quanti giorni indietro considerare al primo avvio. Una volta configurato, il connettore interroga periodicamente GVM e importa da solo i report completati — non serve più esportare e caricare file manualmente per quella sorgente.

## Integrazione JIRA

Per team che tracciano il lavoro anche su JIRA, un Amministratore può configurare la sincronizzazione bidirezionale: creazione automatica di ticket per nuove vulnerabilità (secondo criteri configurabili) e aggiornamento di stato in entrambe le direzioni.

## Notifiche

Le **regole di notifica** (accessibili dalla relativa voce di menu, gestite da un Amministratore) decidono chi viene avvisato, quando e su quale canale, in base a condizioni configurabili (es. severità, team assegnato). Per ciascuna regola puoi impostare:

- priorità e condizioni di attivazione;
- canali di invio: email, Slack, Telegram;
- se l'invio è immediato o raggruppato, con un intervallo minimo tra due notifiche simili (throttling) per evitare di sommergere le persone di messaggi;
- eventuali "orari di silenzio" in cui non inviare notifiche non urgenti.

Perché email/Slack/Telegram funzionino davvero servono, rispettivamente: un server SMTP configurato (capitolo 4), un webhook Slack (personale in Profilo, o di team nella pagina Team — entrambi testabili con un pulsante dedicato prima di fidarsene), e un bot Telegram configurato dall'amministratore per l'istanza.

## Webhook SOAR in uscita (uso avanzato)

Per integrazioni con piattaforme SOAR esterne, SentinelCore può inviare eventi in uscita verso un webhook configurato da un Amministratore — utile per orchestrare automazioni di risposta al di fuori di SentinelCore stesso.
