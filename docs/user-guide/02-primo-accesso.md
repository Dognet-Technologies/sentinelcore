# 2. Primo accesso

## Login

Apri il browser all'indirizzo indicato al termine dell'installazione (es. `https://<indirizzo-server>`). Il certificato TLS auto-firmato genererà un avviso di sicurezza nel browser al primo accesso: è normale per un'istanza appena installata — accetta l'eccezione per procedere (oppure configura un certificato valido, vedi capitolo 1).

Accedi con le credenziali admin annotate durante l'installazione:

- **Utente**: `admin`
- **Password**: quella generata e stampata a fine installazione

## Primo cambio password

Subito dopo il primo accesso, vai su **Profilo** (icona utente in alto a destra → *Profilo*) e cambia la password. È l'unica azione di sicurezza che ti consigliamo di fare prima di ogni altra cosa: l'account admin creato dall'installer non forza da solo un cambio password, quindi finché non lo fai la password stampata durante l'installazione resta valida.

Dalla stessa pagina Profilo puoi anche:

- caricare una foto profilo o scegliere uno dei due avatar predefiniti per il tuo ruolo;
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

Il capitolo successivo spiega nel dettaglio cosa può fare ciascuno dei tre ruoli disponibili.
