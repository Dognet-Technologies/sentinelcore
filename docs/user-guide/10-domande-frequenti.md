# 10. Domande frequenti

**Il browser mostra un avviso di sicurezza/certificato non valido al primo accesso.**
Normale se non hai ancora configurato un certificato TLS valido: SentinelCore genera un certificato auto-firmato per l'istanza. Puoi accettare l'eccezione nel browser, oppure configurare un dominio reale con certificato Let's Encrypt (vedi la documentazione tecnica `packaging/HTTPS.md`).

**Ho dimenticato la password: come la recupero?**
Non esiste un recupero password "self-service" via email: è una scelta di sicurezza deliberata. Chiedi a un Amministratore, o al Team Leader del tuo team, di impostarti una password temporanea da **Utenti** — al login successivo ti verrà chiesto di sceglierne una nuova. Se sei l'unico account amministratore e hai perso l'accesso, serve un intervento diretto sul server da parte di chi lo gestisce.

**Il pulsante "Testa" dell'SMTP dice che l'invio è fallito.**
Verifica in ordine: server e porta corretti, username/password corretti (se hai lasciato vuota la password pensando restasse quella già salvata, verifica che sia davvero già stata impostata in precedenza), che il server SMTP sia raggiungibile dal server SentinelCore (non dal tuo browser — è il backend a connettersi), e che non ci sia un firewall che blocca la porta usata.

**Il pulsante "Testa" del webhook Slack non funziona.**
Controlla che l'URL sia un vero "Incoming Webhook" di Slack (inizia con `https://hooks.slack.com/`) generato dalla configurazione dell'app Slack, non un link generico al canale.

**Le email di riepilogo/avviso non arrivano anche se SMTP è configurato.**
Controlla che l'interruttore "Invio email abilitato" in Impostazioni → SMTP sia acceso, e che l'utente destinatario abbia le relative opzioni attive in Impostazioni → Notifiche (o Profilo, per gli avvisi personali via Slack).

**Un report filtrato per team mostra dati dell'intera azienda.**
Se questo accade, verifica di essere su una versione aggiornata: nelle versioni precedenti alla 1.2.0 alcune sezioni del report di gestione (Metriche, Analisi del rischio, Dettaglio vulnerabilità) non applicavano correttamente il filtro per team — un problema corretto a partire da quella versione. Aggiorna l'istanza (capitolo 1) se non l'hai già fatto.

**La scansione di rete non trova nulla, o trova meno dispositivi del previsto.**
Verifica che la subnet configurata sia effettivamente quella su cui si trova SentinelCore (o che esista una rotta verso di essa), e che il tipo di scansione scelto sia adatto: uno scan "ping" o "ARP" trova meno informazioni di uno scan "full", che richiede però privilegi di rete più ampi sul server.

**Non vedo alcune voci di menu che mi aspetto (Team, Utenti, Report, Piani di remediation, Import scanner).**
Sono visibili solo a Team Leader e Amministratore. Se il tuo ruolo è "Utente", è normale non vederle — vedi il capitolo 3 per il dettaglio dei permessi per ruolo.

**Dopo un aggiornamento il servizio non riparte.**
Lo script di aggiornamento esegue da solo un controllo di salute e, se le migrazioni del database falliscono, ripristina automaticamente la versione precedente. Se invece le migrazioni sono andate a buon fine ma il servizio non risponde comunque, consulta i log (`journalctl -u sentinelcore -n 100`) e, in caso di dubbio, usa il backup del database creato automaticamente prima dell'aggiornamento (si trova in `/opt/sentinelsuite/sentinelcore/backups/`).
