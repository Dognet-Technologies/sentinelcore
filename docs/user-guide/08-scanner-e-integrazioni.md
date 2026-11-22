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

## Connettore Nessus diretto

Lo stesso tipo di collegamento è disponibile per **Tenable Nessus**, sia nell'edizione gratuita *Essentials* sia in *Professional*. Non serve indicare quale delle due usi: SentinelCore la riconosce da solo e la mostra nel test di connessione. La release certificata è la **10.12.x**. Le altre 10.x vengono segnalate come «non certificate» ma di norma funzionano; le versioni con un numero principale diverso vengono indicate come non supportate.

Dalla pagina **Plugin**, un Amministratore apre il menu contestuale della riga *Tenable Nessus* → **Configura** e inserisce:

- l'**URL** di Nessus (es. `https://nessus.lan:8834`). Se Nessus usa ancora il certificato self-signed dell'installazione, disattiva la verifica TLS;
- le **chiavi API**, consigliate: in Nessus si trovano in *Settings → My Account → API Keys → Generate*. La secret key viene mostrata una sola volta, e rigenerarla invalida quella precedente. In alternativa puoi usare **utente e password**, se la tua edizione non mostra la scheda delle chiavi API;
- facoltativamente il **nome della scansione** da seguire. Lasciandolo vuoto vengono importate tutte le scansioni visibili all'utente;
- l'**intervallo di polling**, cioè ogni quanti minuti cercare esecuzioni nuove (da 1 a 1440, predefinito 30), e quanti giorni di storico importare al primo avvio.

**Test connessione** verifica raggiungibilità e credenziali senza salvare. Mostra edizione, versione, numero di scansioni visibili, il modo in cui verranno letti i risultati e un avviso se la scansione indicata non esiste. Dopo il salvataggio attiva il plugin con **Attiva/Disattiva**.

Il connettore è **in sola lettura**: non crea e non avvia scansioni, che restano gestite in Nessus. A ogni giro legge le esecuzioni completate dopo l'ultima importata e le importa con la stessa deduplica dell'import da file. *Professional* e le altre edizioni le scaricano in formato `.nessus`. *Essentials* non permette l'export via API, quindi i risultati vengono letti dalle pagine di dettaglio di host e plugin: il contenuto importato è lo stesso. Ricorda che Essentials limita ogni scansione a 5 indirizzi IP. Le voci puramente informative (severità *Info*) non vengono importate. Se un'esecuzione non si riesce a scaricare, il connettore si ferma lì e la riprova al giro successivo, senza saltarla. Per le credenziali conviene un utente Nessus dedicato che possa solo vedere i risultati.

Nello storico di **Scanner imports** la colonna *Scanner* riporta l'edizione rilevata, per esempio *Nessus Essentials* o *Nessus Professional*.

## Sincronizza ora

I connettori che importano report (OpenVAS e Nessus) hanno nella finestra di configurazione il pulsante **Sincronizza ora**. Avvia subito un giro, senza aspettare l'intervallo di polling: è utile appena finisce una scansione lanciata a mano. Usa la configurazione salvata, quindi salva prima eventuali modifiche, e il plugin deve essere attivo. Se in quel momento il giro automatico è già in corso, il pulsante lo segnala invece di importare due volte.

## Integrazione JIRA

Per team che tracciano il lavoro anche su JIRA, un Amministratore può configurare la sincronizzazione bidirezionale: creazione automatica di ticket per nuove vulnerabilità (secondo criteri configurabili) e aggiornamento di stato in entrambe le direzioni.

## Notifiche

Le **regole di notifica** (accessibili dalla relativa voce di menu, gestite da un Amministratore) decidono chi viene avvisato, quando e su quale canale, in base a condizioni configurabili (es. severità, team assegnato). Per ciascuna regola puoi impostare:

- priorità e condizioni di attivazione;
- canali di invio: email, Slack, Telegram;
- se l'invio è immediato o raggruppato, con un intervallo minimo tra due notifiche simili (throttling) per evitare di sommergere le persone di messaggi;
- eventuali "orari di silenzio" in cui non inviare notifiche non urgenti.

Perché email/Slack/Telegram funzionino davvero servono, rispettivamente: un server SMTP configurato (capitolo 4), un webhook Slack (personale in Profilo, o di team nella pagina Team — entrambi testabili con un pulsante dedicato prima di fidarsene; l'indirizzo viene controllato e deve essere un vero *Incoming Webhook* di Slack, `https://hooks.slack.com/…`), e un bot Telegram configurato dall'amministratore per l'istanza.

## Webhook SOAR in uscita (uso avanzato)

Per integrazioni con piattaforme SOAR esterne, SentinelCore può inviare eventi in uscita verso un webhook configurato da un Amministratore — utile per orchestrare automazioni di risposta al di fuori di SentinelCore stesso.
