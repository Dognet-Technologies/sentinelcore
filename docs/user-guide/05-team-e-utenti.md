# 5. Team e utenti

## Team

La pagina **Team** (visibile a Team Leader e Amministratore) elenca i team esistenti. Per ciascun team puoi configurare:

- **Nome e descrizione**
- **Competenze (skill)** — l'elenco di competenze del team, usato dal motore di assegnazione automatica per abbinare le vulnerabilità al team più adatto
- **Contatti e integrazioni**:
  - email di contatto del team;
  - webhook Slack del team — il canale condiviso su cui arrivano gli avvisi automatici (es. scoperta di una vulnerabilità critical), indipendente dalle notifiche email personali di ciascun membro. Un pulsante **Testa** invia subito un messaggio di prova sul canale, per verificare che l'URL sia corretto prima di salvare;
  - chat ID Telegram del team, per chi usa quel canale (richiede che un amministratore abbia configurato un bot Telegram per l'istanza).
- **Membri del team** — puoi aggiungere un utente esistente della piattaforma (cercandolo per nome/email) oppure un membro "esterno" che non ha un proprio account SentinelCore ma partecipa via nome ed email (utile per referenti esterni destinatari di notifiche, non per l'uso operativo del prodotto). Ogni membro ha un ruolo interno al team: **leader** o **contributor**.

## Utenti

La pagina **Utenti** (visibile a Team Leader e Amministratore) mostra l'elenco di tutti gli account: username, email, ruolo di piattaforma e competenze (skill) individuali.

- Un **Amministratore** può creare nuovi account, cambiarne username e ruolo, e (a seconda della configurazione dell'istanza) sbloccare account bloccati per troppi tentativi di login falliti.
- Un **Team Leader** può modificare email, password e competenze dei membri del **proprio** team, ma non cambiarne username o ruolo di piattaforma — quelle operazioni restano riservate all'Amministratore.

Quando un amministratore o team leader imposta una password temporanea per un altro utente, all'account viene marcato l'obbligo di cambiarla al primo accesso successivo.

## Competenze (skill)

Le competenze sono un catalogo condiviso (es. "Linux", "Windows Server", "Networking", "Web Application", ecc.) assegnabile sia a livello di team sia di singolo utente. Sono il criterio con cui il motore di **assegnazione automatica** (capitolo 4, sezione "Assegnazione vulnerabilità") sceglie a chi instradare una nuova vulnerabilità: più le competenze di un team/utente combaciano con la natura della vulnerabilità scoperta (es. servizio, sistema operativo), più è probabile che venga scelto.
