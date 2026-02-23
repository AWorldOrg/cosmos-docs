### Termini architetturali

**Active-active**: configurazione multi-regione dove tutte le regioni sono operative simultaneamente.

**Multi-tenant**: architettura dove più clienti (tenant) condividono la stessa infrastruttura con isolamento logico.

**Serverless**: modello architetturale dove il cloud provider gestisce automaticamente allocazione risorse senza provisioning manuale server.

**Workspace**: ambiente isolato per un cliente (production, staging, dev).

### Termini sicurezza

**ABAC (Attribute-Based Access Control)**: controllo accessi basato su attributi dinamici dell'utente e contesto.

**JWT (JSON Web Token)**: standard per token di autenticazione/autorizzazione che contiene claims firmati crittograficamente.

**MFA (Multi-Factor Authentication)**: autenticazione che richiede multiple forme di verifica identità.

**OTP (One-Time Password)**: password usa-e-getta valida per singola sessione o transazione.

**RBAC (Role-Based Access Control)**: controllo accessi basato su ruoli predefiniti con permessi statici.

**WAF (Web Application Firewall)**: firewall che ispeziona traffico HTTP per bloccare attacchi web.

### Termini compliance

**DPA (Data Processing Agreement)**: accordo che definisce ruoli e responsabilità nel trattamento dati personali.

**GDPR (General Data Protection Regulation)**: regolamento europeo sulla protezione dati personali.

**ISMS (Information Security Management System)**: sistema di gestione sicurezza informazioni secondo ISO 27001.

**Privacy by Design**: principio che integra privacy fin dalla progettazione sistemi.

**RPO (Recovery Point Objective)**: quantità massima di dati che può essere persa in disaster scenario.

**RTO (Recovery Time Objective)**: tempo massimo per ripristinare servizio dopo disaster.

### Termini operativi

**Failover**: processo automatico di passaggio a sistema backup in caso di guasto primario.

**Health check**: monitoraggio automatico stato servizi per rilevamento guasti.

**Throttling**: limitazione del rate di richieste per prevenire abusi e garantire un utilizzo equo.

### Termini gamification

**Activity**: azione tracciabile dell'utente (TDA) che alimenta il sistema di gamification. Può essere da catalogo o personalizzata.

**Achievement**: riconoscimento visibile assegnato al raggiungimento di traguardi. Include badge (ricompense statiche) e livelli (tier di progressione).

**JSONLogic**: linguaggio di espressioni flessibile utilizzato nella piattaforma per definire condizioni, calcoli e regole senza modifiche al codice.

**Leaderboard Configuration**: template che definisce cosa viene classificato in una leaderboard — selezione utenti, aggregazione metriche e calcolo del punteggio.

**Learning Group (LPG)**: sotto-sezione all'interno di un Learning Path che organizza elementi di contenuto correlati (slide, quiz) con regole di completamento indipendenti.

**Learning Path (LP)**: esperienza lineare di microlearning composta da elementi eterogenei (slide, quiz, learning group, attività). Supporta origini da catalogo, AI e personalizzate.

**Mission**: obiettivo strutturato che traccia il progresso dell'utente verso un target. Supporta tipi individuali e di gruppo con matching, timeframe e regole di assegnazione configurabili.

**Mission Rule**: regola automatica che assegna missioni agli utenti in base a condizioni. Supporta modalità di assegnazione lazy, event-driven e scheduled.

**Reward Rule**: regola automatica che distribuisce valuta virtuale quando specifiche condizioni sono soddisfatte. Può fare matching su missioni, attività, quiz, learning path e altre entità.

**Runtime Leaderboard**: istanza specifica di una configurazione leaderboard, vincolata a un timeframe (permanent, range o recurring) con il proprio ciclo di vita.

**Streak**: misura della costanza dell'utente nel tempo, che traccia periodi consecutivi di engagement (giorni o settimane). Supporta freeze, perfect period e goal target.

**Tag**: coppia namespace-variant utilizzata per categorizzazione e targeting su diverse entità (utenti, attività, missioni, contenuti).

**TDA (Tractable Digital Activity)**: qualsiasi azione tracciabile dell'utente che può attivare dinamiche di gamification.

**Virtual Currency**: tipo di punto configurabile all'interno di un workspace, con tracciamento del bilancio indipendente, storico transazioni e vincoli.
