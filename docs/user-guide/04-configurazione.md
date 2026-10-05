# 4. Configurazione

Tutte le impostazioni di sistema si trovano in **Impostazioni** (visibile a tutti i ruoli, ma la maggior parte delle sezioni è modificabile solo da un Amministratore). Il menu laterale della pagina elenca le sezioni descritte qui sotto. Se apri una sezione riservata all'Amministratore senza averne i permessi, la pagina lo dice con un avviso esplicito invece di restare vuota o in caricamento.

## Preferenze

Scelta del tema grafico dell'interfaccia: 11 temi, tra cui SentinelCore Professional Dark (predefinito), Dognet Professional e Dognet Black, i quattro temi Entuity (Light, Dark, Midnight Blue, Arctic Blue), e i temi Minimal, Modern Tech, Cyberpunk ed Enterprise. È una preferenza personale, salvata per l'utente che l'ha impostata.

I colori di testi, pulsanti e livelli di gravità (Critical/High/Medium/Low) di ogni tema sono verificati per rispettare i rapporti di contrasto WCAG AA, quindi restano leggibili in qualsiasi tema, chiaro o scuro.

## Notifiche

Il canale **in-app** (la campanella in alto) è sempre attivo, indipendentemente da tutto quello che segue. Questa pagina decide invece **cosa** ti arriva anche via **email e Slack personale** (il webhook impostato in Profilo) — perché queste email/Slack arrivino davvero, un amministratore deve aver configurato un server SMTP funzionante (sezione successiva) e/o tu stesso un webhook Slack in Profilo.

**Interruttori generali**:

- **Email** — interruttore generale del canale email;
- **Avviso vulnerabilità critical** — invia un'email quando viene scoperta una vulnerabilità critical assegnata al tuo team;
- **Report settimanale** — invia un'email di riepilogo settimanale delle vulnerabilità.

**Eventi personali** (visibili a tutti i ruoli — riguardano il lavoro assegnato a te o al tuo team):

- Ti viene assegnata una vulnerabilità (a te direttamente o al tuo team);
- Il tuo team riceve un nuovo piano di remediation — un piano ancora in **bozza** non genera nessuna notifica: l'avviso parte quando il piano esce dalla bozza (diventa Attivo).

**Eventi operativi** (visibili solo a Team Leader e Amministratore — riguardano la gestione del team/dell'istanza, non solo il tuo lavoro):

- Un utente cambia lo stato di una vulnerabilità (presa in carico, risolta, chiusa);
- Viene creata una nuova vulnerabilità (manualmente o da un import scanner — in questo caso ricevi un riepilogo del batch, non un'email per ogni riga importata);
- Viene scoperto un nuovo host dal Network Discovery;
- Una scansione di rete **periodica** (quella pianificata in Impostazioni → Network Discovery, non gli avvii manuali) è completata;
- Uno o più host risultano offline in una scansione.

Le **menzioni** (`@nomeutente` in un commento) generano invece sempre una notifica in-app, e solo per le persone citate: nessun altro membro del team viene avvisato.

Ognuna di queste preferenze è indipendente dalle altre: puoi ad esempio ricevere email sulle vulnerabilità assegnate ma non sui report settimanali, o viceversa.

## SMTP (solo Amministratore)

Configurazione del server di posta usato per gli avvisi critici, i report settimanali e le notifiche di avanzamento dei piani di remediation:

| Campo | Descrizione |
|---|---|
| Server SMTP | Hostname del server di invio (es. `smtp.gmail.com`) |
| Porta | Porta SMTP (tipicamente 587 per STARTTLS) |
| Username | Utente per l'autenticazione SMTP |
| Password | Password SMTP — una volta salvata, il campo resta vuoto: lascialo vuoto se non vuoi cambiarla |
| Indirizzo mittente | Se vuoto, viene usato lo username come mittente |
| Invio email abilitato | Interruttore generale: se spento, nessuna email parte anche se le regole di notifica sono configurate |

Dopo aver inserito i parametri, usa il pulsante **Testa connessione**: invia una vera email di prova alla casella dell'amministratore che ha premuto il pulsante — se arriva, la configurazione è corretta. Puoi testare anche prima di salvare, per verificare i parametri senza doverli prima confermare.

## Sicurezza

- **Autenticazione a due fattori (2FA)** — attiva/disattiva il 2FA per il proprio account (vedi capitolo 2).
- **Timeout sessione** — tempo di inattività (15 minuti, 30 minuti, 1 ora, 2 ore o 8 ore) dopo il quale la sessione scade automaticamente e viene richiesto un nuovo login. Si applica per utente, non globalmente. L'inattività conta davvero anche con la pagina aperta: gli aggiornamenti automatici in background non mantengono viva la sessione, mentre l'uso reale (clic, tastiera) sì.
- **Sessioni attive** — dal proprio profilo ciascuno può vedere e chiudere le proprie sessioni. Le sessioni di un utente vengono chiuse automaticamente quando la sua password cambia, quando l'account viene bloccato o eliminato.
- **Protezioni dell'accesso** — i tentativi di login (e di conferma 2FA) sono limitati per indirizzo IP, per rallentare chi prova password a caso; un codice 2FA già usato non viene accettato una seconda volta.

## Server MCP (solo Amministratore)

Questa sezione espone SentinelCore ad **agenti AI autorizzati** tramite il protocollo MCP (Model Context Protocol), per consultare — e, se la chiave lo consente, agire su — vulnerabilità e punteggi di rischio in modo programmatico.

- **Endpoint** — l'indirizzo a cui un client MCP deve connettersi, con relativo frammento di configurazione JSON pronto da copiare.
- **Chiavi API** — ogni agente si autentica con una chiave dedicata, non con le credenziali di un utente umano. Per ogni chiave puoi vedere nome, prefisso, ambito (scope), data di creazione, ultimo utilizzo e scadenza, e revocarla in qualsiasi momento.
- **Ambito (scope) della chiave**:
  - **read** — l'agente può solo consultare dati (vulnerabilità, rischio, asset);
  - **write** — l'agente può anche compiere azioni (es. cambiare lo stato di una vulnerabilità, assegnarla, avviare una scansione). **Solo un Amministratore può creare una chiave con scope write** — è un ambito potenzialmente ad alto impatto, da concedere con cautela e solo ad agenti realmente fidati.

Se non usi integrazioni con agenti AI, questa sezione può restare semplicemente inutilizzata: non ha alcun effetto sul resto del sistema finché non generi una chiave.

## Network Discovery

Configura la scansione di rete automatica periodica (vedi anche capitolo 7):

- **Auto-rescan** — abilita/disabilita la scansione ricorrente e ne imposta la frequenza (da ogni ora a ogni 2 settimane);
- **Subnet di destinazione** — una o più subnet CIDR da scansionare (es. `192.168.1.0/24`); per subnet non direttamente raggiungibili serve una rotta statica configurata sul server;
- **Opzioni nmap** — tipo di scansione (full/ARP/ping), timing (da T0 "paranoid" a T5 "insane"), porte TCP da controllare, numero di porte UDP top da controllare, rilevamento OS e rilevamento versione dei servizi;
- **Modalità avanzata** — è possibile scrivere a mano gli argomenti nmap, per chi conosce lo strumento e vuole un controllo fine; l'anteprima del comando che verrà eseguito è sempre visibile prima di salvare. Per sicurezza le scansioni girano tramite un componente privilegiato dedicato che accetta solo un **elenco di opzioni consentite** e target validi (IP, CIDR, intervalli, nomi host): opzioni che leggono o scrivono file (come `-iL` o `-oN`) o script NSE vengono rifiutate, e un'opzione non ammessa produce un errore chiaro invece di una scansione parziale.

## Logging

Configurazione del file di log applicativo: livello (da `trace`, il più dettagliato, a `error`, il più silenzioso — default `warn`), percorso del file di destinazione, giorni di conservazione degli archivi compressi. Le modifiche a livello e destinazione richiedono un riavvio del servizio per essere applicate; la conservazione (retention) invece si applica subito.

## Assegnazione vulnerabilità

Decide come vengono prese in carico le vulnerabilità non ancora assegnate:

- **Automatica** — un processo in background assegna le nuove vulnerabilità dopo un ritardo configurabile (default 24 ore), abbinandole a team/utenti in base alle competenze (skill) dichiarate;
- **Manuale** — restano in attesa finché un amministratore non le assegna a mano (con un eventuale ritardo di "fallback manuale" oltre il quale scatta comunque un'assegnazione automatica di sicurezza).

## Override permessi utente

Per policy predefinita, un Utente semplice che vuole modificare alcuni dati sensibili (campi di un dispositivo, titolo/descrizione di una vulnerabilità, ricalcolo del punteggio di rischio) non li modifica direttamente: crea una **proposta** che un amministratore o il team leader del team competente approva o rifiuta. Questa sezione permette di **disattivare quel workflow di proposta** per capacità specifiche, dando agli utenti modifica diretta:

| Capacità | Se attiva |
|---|---|
| Modifica device | L'utente modifica direttamente criticità, tag, note e proprietario di un dispositivo, senza passare da una proposta |
| Modifica metadata vulnerabilità | L'utente modifica direttamente titolo e descrizione di una vulnerabilità (punteggio di rischio, CVSS e severity restano comunque riservati ad admin/team leader) |
| Ricalcolo punteggio di rischio | L'utente può forzare da solo il ricalcolo del punteggio di rischio di una vulnerabilità nel proprio ambito |

Ogni modifica diretta fatta grazie a un override attivo resta comunque tracciata nella cronologia dell'oggetto modificato.

## Database

Una vista di sola lettura sullo stato del database: stato online/offline, nome del database, dimensione totale, connessioni attive rispetto al limite massimo, e conteggio righe per ciascuna tabella. Utile per una diagnosi rapida senza dover accedere al server via terminale.
