# Docker compatibility notice

Attenzione: al momento non raccomandiamo di utilizzare Docker per le build di SentinelCore per il prossimo rilascio stabile di Rust. Alcune dipendenze e toolchain (in particolare SQLx con cache e alcune versioni di librerie native) hanno comportamenti non compatibili con container leggeri o immagini ufficiali preconfezionate.

Motivazioni:
- SQLx richiede una connessione PostgreSQL per la generazione della cache di query (cargo sqlx prepare) e questo può complicare il workflow in container senza servizi persistenti.
- Alcune immagini Docker ufficiali per Rust/Ubuntu/Alpine non includono librerie native necessarie o usano versioni diverse (libssl, libpq) che causano linking fail.

Raccomandazioni temporanee:
- Usa un host Debian 12/13 o una VM (packer) per build ripetibili.
- Se desideri utilizzare container, crea un runner che includa esattamente le versioni native richieste (libssl, libpq) e avvia un servizio PostgreSQL all'interno del job.
- Aggiorneremo questa nota quando il supporto per la prossima versione stabile di Rust sarà disponibile e avremo immagini Docker ufficiali testate per SentinelCore.

Per ora, vedi gli script in scripts/deployment per build native e packer/ per immagini VM.