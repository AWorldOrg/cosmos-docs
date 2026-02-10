Il nuovo prodotto rappresenta una trasformazione strategica del modello AWorld, con l'obiettivo di offrire alle aziende un sistema di *gamification* completamente integrabile nei loro ecosistemi digitali. A differenza della soluzione originale, che fornisce un'esperienza *end-to-end* all'interno di un'unica piattaforma, questa evoluzione consente ai clienti di accedere direttamente agli strumenti di *engagement* di AWorld e di adattarli alle proprie esigenze specifiche.

## 2.1 Una nuova infrastruttura

Adottare un'architettura *API-first* significa trasformare la *gamification* in un servizio modulare e scalabile, facilmente integrabile in applicazioni, siti web e sistemi aziendali esistenti, senza vincoli infrastrutturali. Questo approccio garantisce maggiore scalabilità e flessibilità, permettendo alle organizzazioni di sfruttare il potenziale della piattaforma senza dover sviluppare complessi sistemi interni per la gestione dell'*engagement*.

In questa nuova configurazione, il prodotto agisce come un *layer* applicativo che migliora l'esperienza utente attraverso strumenti strutturati per incentivare la partecipazione, misurare l'engagement e personalizzare i percorsi di interazione. I clienti possono configurare i propri ambienti digitali integrando meccaniche di gioco, contenuti interattivi e percorsi esperienziali, senza compromettere la propria identità di marca o i propri obiettivi strategici.

Per supportare questa transizione, AWorld ha costruito il proprio software su un'architettura modulare organizzata in quattro *layer* principali, che consentono alle aziende di integrare in modo indipendente e scalabile gli elementi di *gamification*, garantendo al contempo la massima flessibilità operativa. Ogni *layer* ha una funzione specifica:

### **2.1.1 Account & User Layer**

La base della piattaforma, responsabile della gestione degli utenti, dei permessi e dell'autenticazione. Questo componente garantisce un'infrastruttura scalabile, permettendo a più organizzazioni di utilizzare il servizio mantenendo un'adeguata separazione dei dati e possibilità di personalizzazione. Include strumenti come la gestione *JWT* e la gestione *Server-to-Server*, essenziali per l'integrazione con i sistemi esistenti dei clienti.

### **2.1.2 Gamification Layer**

Il cuore del sistema di *engagement*, che fornisce le meccaniche di gioco essenziali. Include funzionalità come attività, missioni, progressione di livello, *leaderboard*, sistema a punti, *achievements* e notifiche. Questo *layer* consente alle aziende di personalizzare l'esperienza utente introducendo dinamiche di competizione e ricompensa allineate ai propri obiettivi.

> Il sistema di *gamification* di AWorld si basa su un principio fondamentale: **l'utente deve poter compiere un'azione significativa**, che diventa il motore del suo engagement. Questa azione, chiamata ***Tractable Digital Activity (TDA)***, rappresenta qualsiasi attività tracciabile che può essere utilizzata per attivare le dinamiche di gioco.

Nel nuovo sistema, il cliente è libero di definire cosa costituisce una **TDA**, adattandola al proprio contesto: un'**attività** potrebbe consistere nel *pubblicare un post*, *leggere un contenuto*, *scansionare un codice QR*, *completare un quiz*, o qualsiasi altra interazione monitorabile digitalmente.

Ogni **TDA** alimenta il sistema, contribuendo all'accumulo di punti, al progresso delle missioni e all'attivazione delle ricompense, trasformando le azioni degli utenti in un percorso di engagement misurabile e personalizzato.

### **2.1.2 Activity Plugin Layer**

Questo *layer* abilita e fornisce accesso a **modelli di attività predefiniti**, sviluppati e validati da AWorld attraverso la propria esperienza con l'app mobile. Sebbene ogni cliente possa definire le proprie **Tractable Digital Activities (TDAs)** personalizzate, AWorld offre un set di **modelli di attività ottimizzati** che possono essere utilizzati immediatamente per accelerare l'implementazione della *gamification*.

Tra questi, le **Stories** coinvolgono gli utenti attraverso contenuti interattivi, mentre i **Quizzes** propongono domande a risposta multipla per stimolare l'apprendimento e l'engagement. Le **Routines** sono sequenze di azioni ricorrenti che gli utenti devono completare nel tempo.

Inoltre, il sistema include modelli basati su dati di mobilità e benessere, come i **Mobility Milestones**, che tracciano i comportamenti di mobilità sostenibile, e i **Wellness Milestones**, che monitorano passi e minuti di attività fisica. Questi sono disponibili solo se il punto di contatto dell'utente è un **dispositivo mobile**, consentendo l'integrazione con i sensori dello smartphone o con i dati provenienti da app di monitoraggio della salute.

Grazie all'*Activity Plugin Layer*, i clienti possono **combinare le proprie attività con le soluzioni collaudate di AWorld**, accelerando il deployment della *gamification* e garantendo al contempo un'esperienza utente efficace e coinvolgente fin dal primo giorno.

### **2.1.3 Catalog Layer**

Il *Catalog Layer* gestisce l'organizzazione e la distribuzione dei contenuti disponibili sulla piattaforma, offrendo ai clienti l'accesso alle risorse predefinite di AWorld o la possibilità di personalizzare le proprie attività.

Sebbene i clienti possano configurare le proprie **TDA**, AWorld fornisce un catalogo strutturato di **contenuti validati**, che consente un deployment più rapido della *gamification*. Ad esempio, un cliente che adotta il modello **Stories** può creare i propri contenuti oppure selezionarli dal catalogo **Stories** di AWorld, che offre una raccolta curata di articoli e materiali pronti all'uso. Lo stesso vale per i **Quizzes**, che dispongono di una banca di domande e test interattivi, e per le **Missioni**, con sfide precostituite basate su anni di esperienza sulla piattaforma.

Questo *layer* non solo accelera l'integrazione della *gamification*, ma garantisce anche attività di alta qualità, fornendo un solido punto di partenza per i clienti che desiderano lanciare rapidamente esperienze coinvolgenti.

L'adozione di questa nuova architettura a livelli migliora l'efficienza tecnica della piattaforma e apre nuove opportunità di crescita per AWorld, ampliando il pubblico di riferimento e consentendo l'ingresso in nuovi segmenti di mercato.

### **2.1.4 *AI Content Generation*: supporto alla creazione di *Stories* interattive**

Molti clienti di AWorld desiderano personalizzare la piattaforma ma spesso si trovano di fronte a una **barriera operativa: la creazione di contenuti richiede tempo e competenze specifiche**. Per affrontare questa sfida, AWorld sta sperimentando l'integrazione dell'intelligenza artificiale per **supportare la creazione di contenuti interattivi**, a partire dal modello di attività **Stories**. L'esperienza ha dimostrato che, sebbene molti clienti vogliano personalizzare la piattaforma, spesso **non hanno il tempo o le risorse** per produrre contenuti di qualità in modo autonomo.

Per questo motivo, AWorld sta sviluppando un sistema che, attraverso l'intelligenza artificiale, **assisterà i clienti nella gen**