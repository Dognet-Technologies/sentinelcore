# 2. Primo accesso

## Login

Apri il browser all'indirizzo indicato al termine dell'installazione (es. `https://<indirizzo-server>`). Il certificato TLS auto-firmato genererà un avviso di sicurezza nel browser al primo accesso: è normale per un'istanza appena installata — accetta l'eccezione per procedere (oppure configura un certificato valido, vedi capitolo 1).

Accedi con le credenziali admin annotate durante l'installazione:

- **Utente**: `admin`
- **Password**: quella generata e stampata a fine installazione

## Primo cambio password

Subito dopo il primo accesso, vai su **Profilo** (icona utente in alto a destra → *Profilo*) e cambia la password. È l'unica azione di sicurezza che ti consigliamo di fare prima di ogni altra cosa: l'account admin creato dall'installer non forza da solo un cambio password, quindi finché non lo fai la password stampata durante l'installazione resta valida.

Dalla stessa pagina Profilo puoi anche:

- caricare una foto profilo o scegliere uno dei quattro avatar predefiniti per il tuo ruolo;
- impostare la lingua dell'interfaccia (italiano o inglese);
- collegare un webhook Slack personale, per ricevere lì gli stessi avvisi critici dell'email;
- scegliere il tuo **team principale** (se sei membro di più team), usato come riferimento per i filtri e l'ordinamento delle notifiche.

## Attivare l'autenticazione a due fattori (opzionale, consigliato per gli admin)

In **Impostazioni → Sicurezza** puoi attivare il 2FA basato su app authenticator (Google Authenticator, Authy o equivalenti): il sistema mostra un QR code da inquadrare, poi richiede un codice di conferma per completare l'attivazione. Da quel momento il login richiederà, oltre alla password, il codice a 6 cifre generato dall'app.

## Tour rapido dell'interfaccia

La barra laterale a sinistra è organizzata in quattro aree:

| Area | Contenuto | Visibile a |
|---|---|---|
| **Monitor** | Dashboard, Le mie vulnerabilità | Tutti |
| **Gestione** | Vulnerabilità, Host, Topologia di rete, Piani di remediation*, Import scanner* | Tutti (le voci segnate * richiedono ruolo Team Leader o Amministratore) |
| **Report** | Report | Team Leader e Amministratore |
| **Amministrazione** | Team*, Utenti*, Plugin**, Impostazioni | * Team Leader+, ** solo Amministratore |

In alto a destra trovi sempre: ricerca globale, campanella delle notifiche in-app, e il menu del tuo profilo utente.

I dati si **aggiornano da soli**: quando un collega crea un utente, assegna una vulnerabilità o cambia un piano, le liste che hai aperto si ricaricano senza che tu debba premere F5. Passando il mouse su un utente o su un team compare una piccola scheda informativa (ruolo, team, contatti).

### La barra delle tabelle

Sopra ogni tabella trovi la ricerca e, a destra, alcune icone:

- **Colonne** — apre l'elenco delle colonne con una spunta ciascuna: scegli quali vedere. La scelta viene ricordata per quella tabella;
- **Esporta** — scarica la tabella (dove disponibile);
- **Aggiorna** — ricarica i dati;
- nella tabella **Vulnerabilità**, per gli amministratori, **Avvia aggiornamenti** (vedi capitolo 6).

L'ordinamento si cambia cliccando sull'intestazione di una colonna. **Date e orari** sono ovunque in formato europeo: GG/MM/AAAA e ore a 24 ore (es. `09/10/2026, 00:38:58`), anche con l'interfaccia in inglese.

Il capitolo successivo spiega nel dettaglio cosa può fare ciascuno dei tre ruoli disponibili.
