## **5.1 Vantaggi dell'infrastruttura *Serverless***

L'adozione di un'architettura **serverless** è una scelta strategica che massimizza l'efficienza operativa e riduce i costi infrastrutturali. Con questo modello, le risorse computazionali vengono allocate **dinamicamente in base alla domanda**, eliminando la necessità di gestire manualmente server fisici o macchine virtuali dedicate.

Uno dei principali vantaggi è la **scalabilità automatica**, che consente alla piattaforma di gestire i picchi di carico senza compromettere le prestazioni. Ad esempio, quando il numero di richieste API aumenta improvvisamente, AWS Lambda attiva istanze di funzione aggiuntive senza intervento manuale, garantendo una risposta immediata al carico variabile. Ciò è particolarmente utile per scenari in cui gli utenti interagiscono con la piattaforma in modo imprevedibile, come campagne di *engagement* o lanci di iniziative ad alto traffico.

Dal punto di vista economico, l'**ottimizzazione dei costi** è un altro aspetto fondamentale. Il modello *pay-per-use* di AWS prevede che le risorse vengano fatturate solo quando effettivamente utilizzate, evitando sprechi legati al sovradimensionamento dei server. In una soluzione tradizionale, un'azienda dovrebbe prevedere capacità computazionale aggiuntiva per gestire i picchi, sostenendo costi fissi indipendentemente dall'utilizzo effettivo. Con il serverless, questa logica si inverte, riducendo le spese operative e garantendo un'infrastruttura altamente efficiente.

Dal punto di vista della **gestione operativa**, l'infrastruttura serverless riduce drasticamente le esigenze di manutenzione. Aggiornamenti, *patching* e sicurezza a livello infrastrutturale sono gestiti direttamente da AWS, consentendo ai team tecnici di AWorld Lab di concentrarsi sullo sviluppo delle funzionalità di *gamification* senza gestire operazioni di provisioning o monitoraggio manuale dei server.

## **5.2 Modello API: REST con architettura predisposta per GraphQL**

AWorld Lab espone le proprie API attraverso **endpoint REST**, fornendo un modello di interfaccia consolidato e ampiamente adottato che garantisce un'integrazione immediata con qualsiasi stack tecnologico. REST offre semplicità, ampio supporto di strumenti e compatibilità diretta con le infrastrutture client esistenti.

Le API REST della piattaforma seguono una struttura coerente organizzata per dominio, con convenzioni di naming chiare e metodi HTTP standard. Ogni servizio espone un proprio set di endpoint, consentendo ai client di interagire con specifiche funzionalità di *gamification* — come missioni, leaderboard, attività e ricompense — attraverso interfacce dedicate e ben documentate.

L'architettura sottostante è **progettata per supportare GraphQL** come layer API aggiuntivo in futuro. Questo significa che, con l'evolversi delle esigenze dei client, AWorld Lab potrà esporre interfacce GraphQL accanto a REST, offrendo agli sviluppatori un maggiore controllo sui dati restituiti, la possibilità di aggregare informazioni da fonti diverse in una singola richiesta e un ridotto consumo di banda.

Questo approccio garantisce che le aziende possano integrare AWorld Lab oggi utilizzando i familiari pattern REST, con la certezza che l'architettura della piattaforma è pronta a supportare modelli API più avanzati man mano che le loro esigenze crescono.

## **5.3 Gestione dei permessi e transizione RBAC / ABAC**

La sicurezza dei dati e la gestione degli accessi sono elementi fondamentali dell'infrastruttura di AWorld Lab, in particolare per garantire un corretto isolamento tra i diversi clienti nel modello **multi-*tenant***. Per questo motivo, la piattaforma implementa un sistema di controllo degli accessi basato su **RBAC (Role-Based Access Control)**, con la possibilità di evolvere verso un modello più flessibile e granulare come **ABAC (Attribute-Based Access Control)**.

### **5.3.1 RBAC: controllo basato sui ruoli**

Nel modello **RBAC**, ogni utente è associato a un ruolo predefinito con permessi statici. Questa struttura semplifica la gestione degli accessi, consentendo un'assegnazione chiara delle responsabilità. Ad esempio, un amministratore può configurare la piattaforma, creare missioni, gestire gli utenti e monitorare i dati, mentre un moderatore può supervisionare le missioni e interagire con gli utenti senza modificare le regole globali. Gli utenti standard, invece, possono partecipare alle missioni e accumulare progressi, ma non hanno accesso alle configurazioni.

Questo modello è particolarmente utile in contesti in cui ruoli e responsabilità sono ben definiti e statici. Tuttavia, in scenari più complessi, può risultare limitante poiché non consente una gestione dinamica degli accessi basata su condizioni specifiche o sul comportamento degli utenti.

### **5.3.2 ABAC: controllo basato sugli attributi**

Per superare queste limitazioni, **AWorld Lab supporta un modello di autorizzazione ABAC**, che consente di determinare i permessi in modo dinamico in base a una combinazione di attributi dell'utente, della risorsa e del contesto operativo.

A differenza del modello RBAC, che assegna permessi rigidi in base ai ruoli, ABAC consente la definizione di regole più flessibili. Ad esempio, un utente potrebbe avere accesso solo alle missioni che ha creato, mentre alcune funzionalità avanzate potrebbero essere riservate agli utenti con status Premium. Inoltre, l'accesso a determinate risorse potrebbe variare in base a condizioni contestuali, come l'orario del giorno o lo stato di avanzamento di una missione.

Questa transizione offre diversi vantaggi. Da un lato, rende il sistema più scalabile, evitando la necessità di gestire manualmente un gran numero di ruoli e permessi statici. Dall'altro, migliora la sicurezza riducendo i rischi associati a permessi eccessivi o assegnati erroneamente. Grazie a questa flessibilità, le aziende possono personalizzare i livelli di accesso senza ridefinire continuamente le policy, adattando le autorizzazioni in tempo reale alle esigenze operative.

## **5.4 Ottimizzazione delle prestazioni e gestione dei carichi di lavoro**

Per garantire un'esperienza utente fluida e scalabile, AWorld Lab implementa diverse strategie di ottimizzazione delle prestazioni, tra cui caching distribuito, gestione efficiente delle richieste API e load balancing. Questi meccanismi contribuiscono a migliorare la reattività della piattaforma, ridurre la latenza e ottimizzare l'utilizzo delle risorse.

### **5.4.1 Caching distribuito per ridurre la latenza**

Uno degli strumenti chiave per migliorare le prestazioni è il caching, che riduce il numero di query al database e velocizza l'accesso ai dati che cambiano meno frequentemente. Informazioni statiche o semi-statiche, come le configurazioni delle missioni o le regole di gioco, possono essere temporaneamente archiviate in memoria, evitando accessi ridondanti al database e migliorando la velocità di risposta.

Il caching è gestito in modo dinamico, con criteri di invalidazione automatici per garantire che i dati siano sempre aggiornati. Quando vengono apportate modifiche a missioni, ricompense o configurazioni globali, il sistema aggiorna automaticamente la cache, evitando inconsistenze e assicurando un allineamento costante tra i dati visualizzati e quelli effettivi.

I dati altamente dinamici come **punteggi e classifiche** non vengono memorizzati in cache, poiché devono essere aggiornati in tempo reale per riflettere l'ultimo stato delle competizioni e dell'engagement degli utenti. Per questi elementi, il sistema utilizza meccanismi di aggiornamento continuo e una gestione efficiente delle query per garantire velocità e accuratezza nelle risposte.

### **5.4.2 Load balancing per migliorare la distribuzione del traffico**

Per garantire un'elevata disponibilità e reattività del sistema, AWorld Lab utilizza un'architettura distribuita in grado di bilanciare il carico delle richieste API su più istanze e data center. Questo ottimizza l'allocazione delle risorse e instrada le richieste in modo efficiente, riducendo i tempi di risposta e migliorando la scalabilità complessiva della piattaforma.

In caso di picchi di utilizzo o carico elevato su un'area geografica specifica, il sistema può distribuire automaticamente il traffico su più nodi, **garantendo continuità operativa e una gestione fluida delle richieste anche in condizioni di elevata concorrenza**.

## **5.5 Disaster Recovery e Business Continuity**

Per garantire la resilienza della piattaforma, AWorld Lab adotta un'architettura distribuita e una strategia avanzata di **disaster recovery** e **business continuity**, assicurando un rapido ripristino del sistema in caso di guasti critici o eventi imprevisti. Questo approccio riduce il rischio di interruzioni del servizio, proteggendo la disponibilità dei dati e garantendo un'esperienza utente stabile anche in condizioni di emergenza.

### **5.5.1 Replica multi-regione e ridondanza**

AWorld Lab utilizza una configurazione **active-active** su più regioni cloud, garantendo che dati e servizi siano sempre accessibili anche in caso di malfunzionamento di un'area geografica specifica. Tutti i componenti chiave dell'infrastruttura vengono replicati automaticamente per garantire la continuità operativa.

I dati applicativi sono distribuiti su più regioni attraverso **database replicati in tempo reale**, evitando il rischio di perdita di informazioni e garantendo la coerenza tra le diverse istanze. I file statici sono sincronizzati su più data center per garantire un recupero immediato, mentre le API e i servizi applicativi sono distribuiti su più nodi, assicurando una significativa riduzione dei tempi di inattività.

### **5.5.2 Piani di ripristino e tempi di recupero**

Ogni componente della piattaforma è progettato per rispettare rigorosi **Recovery Time Objectives (RTO)** e **Recovery Point Objectives (RPO)**, garantendo che in caso di incidente i dati siano sempre disponibili e il servizio venga ripristinato il più rapidamente possibile.

Grazie alla replica in tempo reale, le informazioni critiche della piattaforma possono essere recuperate quasi istantaneamente, mentre i servizi applicativi possono deviare automaticamente il traffico verso istanze funzionanti senza impatto percepibile per gli utenti. Anche i contenuti statici e gli asset vengono periodicamente sincronizzati tra le regioni per garantire la continuità operativa senza interruzioni prolungate.

### **5.5.3 Monitoraggio e rilevamento automatico delle anomalie**

Per garantire un'elevata affidabilità, AWorld Lab implementa un sistema di **monitoraggio proattivo** che analizza costantemente le metriche di utilizzo e il comportamento delle API. Un'infrastruttura di **registrazione degli eventi e tracciamento** consente di rilevare tempestivamente eventuali anomalie, prevenendo potenziali guasti o minacce alla sicurezza.

In caso di degrado delle prestazioni o tentativi di accesso sospetti, il sistema attiva automaticamente misure di mitigazione, come il **failover verso una regione alternativa** o la limitazione degli accessi per utenti potenzialmente malevoli. Queste strategie contribuiscono a mantenere elevati standard di sicurezza e continuità operativa, minimizzando l'impatto di eventuali interruzioni del servizio.

## **5.6 Strategie avanzate di sicurezza e protezione dei dati**

La protezione dei dati e la sicurezza delle API sono elementi fondamentali per garantire la conformità normativa e proteggere gli utenti da accessi non autorizzati. AWorld Lab implementa un'architettura di sicurezza multilivello che combina crittografia avanzata, prevenzione delle minacce e risposta tempestiva agli incidenti.

### **5.6.1 Crittografia e protezione delle informazioni sensibili**

Tutti i dati gestiti dalla piattaforma sono crittografati sia **in transito** che **a riposo**, garantendo la massima protezione contro accessi non autorizzati o intercettazioni. La crittografia **TLS 1.2/1.3** protegge tutte le comunicazioni API, prevenendo attacchi *man-in-the-middle* e garantendo l'integrità delle trasmissioni. Per la **gestione delle chiavi di crittografia** e la protezione dei dati sensibili, AWorld Lab utilizza un sistema centralizzato, riducendo il rischio di esposizione e garantendo che tutti i dati siano crittografati automaticamente.

### **5.6.2 Prevenzione degli attacchi e protezione delle API**

Per mitigare i rischi di attacchi informatici e garantire la sicurezza delle API, la piattaforma adotta misure di protezione proattive. Un **web application firewall (WAF)** avanzato analizza costantemente il traffico e blocca le richieste sospette, proteggendo da vulnerabilità come *SQL Injection* e *Cross-Site Scripting (XSS)*.

Ogni API è soggetta a policy di **rate limiting**, che limitano il numero di richieste per prevenire abusi o tentativi di attacco DDoS. Inoltre, il traffico è **monitorato in tempo reale da un sistema di rilevamento delle minacce**, che identifica comportamenti anomali e attiva automaticamente contromisure per proteggere l'infrastruttura.

### **5.6.3 Gestione delle violazioni di sicurezza e risposta agli incidenti**

In caso di violazione della sicurezza, AWorld Lab dispone di un **piano di risposta agli incidenti** che prevede una gestione strutturata delle anomalie per minimizzare l'impatto e ripristinare rapidamente il servizio. Il sistema identifica e isola automaticamente le attività sospette, prevenendo la diffusione di potenziali minacce.

Gli avvisi di sicurezza vengono inoltrati in tempo reale ai responsabili della piattaforma, garantendo un intervento tempestivo. Una volta risolto l'incidente, viene condotta un'analisi approfondita per identificare la causa del problema e implementare misure correttive, riducendo il rischio di eventi simili in futuro.

Grazie a queste strategie, la piattaforma garantisce un elevato livello di protezione, assicurando la sicurezza operativa e minimizzando il rischio di esposizione dei dati.
