Questa sezione offre un'analisi dettagliata degli elementi fondamentali del sistema di *gamification* di AWorld Lab: le **attività** compiute dagli utenti, i **contenuti** con cui interagiscono e le **esperienze di apprendimento** che alimentano l'engagement. Per una panoramica architetturale dell'Activity Plugin Layer e del Catalog Layer, si rimanda alla documentazione sull'architettura della piattaforma. Per comprendere come le attività alimentano missioni e ricompense, consultare la documentazione su missioni e progressione.

## Attività: azioni digitali tracciabili

Le **attività** sono gli elementi fondamentali del sistema di *gamification* di AWorld Lab. Ogni attività rappresenta una **Tractable Digital Activity (TDA)** — un'azione tracciabile che alimenta le meccaniche di engagement della piattaforma.

### Modello di attività e tipologie di origine

Ogni attività nel sistema è definita da un identificativo univoco, un nome e una **tipologia di origine** che ne determina la modalità di creazione:

- **Catalog**: attività predefinite dal catalogo validato di AWorld Lab, pronte per l'uso immediato. Le attività da catalogo possono essere sincronizzate automaticamente per ricevere aggiornamenti.
- **Custom**: attività definite dal cliente per adattarsi al proprio contesto aziendale e alle interazioni dei propri utenti.

Tutte le attività supportano la **configurazione multilingua**, consentendo ai clienti di offrire esperienze localizzate su mercati diversi.

### Logging delle attività e tracciamento degli esiti

Ogni volta che un utente esegue un'attività, il sistema crea una voce di **Activity Log** che registra:

- **Outcome**: se l'azione è stata completata con successo o meno.
- **Value**: un valore numerico che rappresenta l'entità dell'azione (predefinito a 1).
- **Tag**: etichette associate per la categorizzazione e il filtraggio.
- **Timestamp**: il momento in cui l'azione è stata completata.

I log delle attività fungono da **trigger primario** per tutte le meccaniche di *gamification* a valle. Quando viene creato un log, il sistema di eventi della piattaforma valuta automaticamente missioni, regole di ricompensa e streak — trasformando ogni azione dell'utente in un'opportunità di engagement.

### Attività custom e integrazione con eventi di terze parti

Oltre alle attività standard, AWorld Lab consente ai clienti di definire **attività custom** personalizzate in base alle proprie esigenze specifiche. Il sistema è in grado di tracciare un'ampia varietà di eventi, tra cui:

- azioni degli utenti all'interno dei touchpoint digitali del cliente, come la pubblicazione di contenuti o il rilascio di recensioni;
- interazioni con dispositivi o piattaforme esterne, come la scansione di codici QR;
- qualsiasi altro evento configurabile in grado di attivare dinamiche di *gamification*.

Le attività custom vengono registrate tramite API attraverso un'**integrazione Server-to-Server (S2S)**, consentendo ai clienti di registrare azioni per conto dei propri utenti da qualsiasi sistema backend.

## Learning Path

I **Learning Path (LP)** sono il modello di contenuto principale di AWorld Lab e offrono **esperienze lineari di microlearning** che guidano gli utenti attraverso percorsi educativi o di engagement strutturati. I Learning Path sostituiscono il modello di contenuto legacy e offrono una flessibilità e un controllo significativamente superiori.

### Struttura e composizione

Ogni Learning Path è definito da:

- **Titolo e descrizione**: metadati che descrivono l'esperienza di apprendimento.
- **Immagine di copertina**: identità visiva del percorso.
- **Durata stimata**: tempo previsto per il completamento, in minuti.
- **Tipologia di origine**: modalità di creazione del contenuto — **Catalog** (predefinito), **AI** (generato dal sistema AI di AWorld Lab) o **Custom** (definito dal cliente).

### Elementi del Learning Path

Un Learning Path contiene un **elenco ordinato di elementi**, che possono essere di diversi tipi:

- **Slide**: contenuti testuali o multimediali per la trasmissione di informazioni.
- **Quiz**: domande interattive per verificare la comprensione.
- **Learning Group**: sotto-sezioni che organizzano elementi correlati tra loro.
- **Attività**: azioni tracciabili integrate nel flusso di apprendimento.

Questa struttura eterogenea consente ai clienti di creare esperienze di apprendimento ricche e variegate, combinando contenuti informativi con valutazioni interattive e attività pratiche.

### Assegnazione e visibilità

I Learning Path vengono erogati agli utenti tramite **Learning Path Assignment**, che controllano quando e come gli utenti accedono ai contenuti:

- **Visibilità**: le assegnazioni possono essere **Unlocked** (immediatamente accessibili) o **Locked** (visibili ma non ancora accessibili, in attesa di un trigger di sblocco).
- **Stati**: ogni assegnazione transita attraverso gli stati **Pending** (prima della data di inizio), **Active** (all'interno dell'intervallo temporale) ed **Ended** (dopo la scadenza dell'intervallo temporale).
- **Intervalli temporali**: le assegnazioni supportano configurazioni **Permanent** (senza data di scadenza), **Range** (date di inizio e fine specifiche) e **Recurring** (periodi ricorrenti).

Questo modello abilita scenari quali il rilascio di contenuti secondo una programmazione, il blocco dell'accesso tramite prerequisiti o la creazione di campagne di apprendimento a tempo limitato.

### Regole di assegnazione: assegnazione e sblocco automatizzati

AWorld Lab mette a disposizione un potente **motore di regole** per automatizzare l'erogazione dei Learning Path:

- Le **regole di assegnazione** creano automaticamente assegnazioni quando gli utenti soddisfano condizioni specifiche, distribuendo i Learning Path da un pool configurabile.
- Le **regole di sblocco** modificano la visibilità delle assegnazioni esistenti da Locked a Unlocked quando le condizioni sono soddisfatte — ad esempio, sbloccando un percorso avanzato al completamento di un prerequisito.

Le regole operano in diverse **modalità di assegnazione**:

- **Lazy**: le assegnazioni vengono create on-demand quando l'utente esplora i contenuti disponibili, se corrisponde alle condizioni della regola.
- **Event**: le assegnazioni vengono attivate in tempo reale dalle azioni dell'utente (come il completamento di un altro Learning Path o l'ottenimento di uno specifico achievement).
- **Scheduled**: le assegnazioni vengono inviate agli utenti a un orario predeterminato.

### Regole di completamento personalizzate

Ogni Learning Path supporta **regole personalizzate** che definiscono come vengono valutati il completamento, l'esito e le condizioni di avvio:

- **Regola di completamento**: determina quando il percorso è considerato completato (es. "completa almeno 3 elementi su 5" o "completa tutti gli elementi in ordine").
- **Regola di esito**: determina se il risultato complessivo è un successo o un fallimento (es. "successo se tutti i quiz sono superati").
- **Regola di avvio**: determina quando il percorso è considerato iniziato.

Queste regole utilizzano un **linguaggio di espressioni flessibile** che consente ai clienti di definire condizioni complesse senza modifiche al codice, adattando la logica di apprendimento alle proprie esigenze specifiche.

### Tracciamento dei progressi

Il sistema tiene traccia dei **progressi dettagliati** di ogni utente su ciascun Learning Path:

- **Stati di avanzamento**: Start, In Progress e Complete.
- **Esito**: Success o Fail, determinato dalla regola di esito configurata.
- **Tracciamento per singolo elemento**: il progresso viene registrato per ogni singolo elemento all'interno del percorso.
- **Posizione corrente**: il sistema memorizza il punto in cui l'utente si è fermato, consentendo una ripresa senza interruzioni.

## Learning Group

I **Learning Group** sono sotto-sezioni all'interno dei Learning Path che organizzano elementi di contenuto correlati tra loro. Funzionano come unità autonome con una propria logica di completamento.

### Tipologie di gruppo e composizione

I Learning Group sono disponibili in tre tipologie:

- **Story**: una sequenza narrativa di slide con un quiz finale opzionale — il formato standard di microlearning.
- **Test**: una sequenza focalizzata sulla valutazione, composta principalmente da quiz.
- **Custom**: un formato flessibile che combina qualsiasi mix di tipologie di contenuto.

Ogni gruppo può contenere **slide, quiz e altri elementi di contenuto**, e supporta le stesse tipologie di origine dei Learning Path: Catalog, AI e Custom.

### Regole di completamento e tracciamento dei progressi

I Learning Group dispongono di **regole di completamento e di esito indipendenti**, valutate separatamente rispetto al Learning Path padre. Questo significa che un gruppo può definire i propri criteri di successo — ad esempio, richiedendo che tutti i quiz siano superati correttamente, anche se il Learning Path complessivo consente il completamento parziale.

Il sistema tiene traccia dei progressi a livello di gruppo e supporta azioni dell'utente come l'aggiunta ai **preferiti** e la **condivisione** dei gruppi.

## Slide e Quiz

### Slide: contenuti testuali e multimediali

Le **Slide** sono l'unità di contenuto fondamentale per la trasmissione di informazioni. Ogni slide supporta due tipologie di contenuto:

- **Slide testuali**: presentano contenuti scritti per informare, educare o guidare l'utente.
- **Slide multimediali**: mostrano immagini, video o altre risorse multimediali.

Le slide possono essere create dal **catalogo** (predefinite), generate dall'**AI** o definite come contenuti **custom**. Il sistema traccia quando ogni slide viene visualizzata e completata.

### Quiz: valutazione interattiva

I **Quiz** offrono una valutazione interattiva all'interno dei Learning Path e come attività autonome. Ogni quiz consiste in una **domanda a scelta singola con una sola risposta corretta**, progettata per consolidare l'apprendimento e stimolare l'engagement.

Le caratteristiche principali includono:

- **Livelli di difficoltà**: i quiz possono essere contrassegnati con un livello di difficoltà per esperienze adattive.
- **Configurazione del posizionamento**: i quiz possono essere posizionati contestualmente all'interno dei flussi di apprendimento.
- **Logging dettagliato**: ogni tentativo viene registrato, inclusa la risposta dell'utente, la risposta corretta e l'esito (successo o fallimento).

### Contenuti da catalogo, custom e generati dall'AI

AWorld Lab mette a disposizione un **ampio catalogo di quiz preconfigurati** pronti per l'uso immediato. I clienti possono inoltre creare **quiz custom** con contenuti personalizzati per il proprio pubblico di riferimento, oppure sfruttare il sistema di **generazione di contenuti tramite AI** di AWorld Lab per produrre quiz automaticamente in base a temi e obiettivi specifici.

## Mobility Assistant

Se AWorld Lab è integrato in un'**applicazione mobile**, i clienti possono attivare il **Mobility Assistant** — un modulo specializzato che traccia gli spostamenti sostenibili degli utenti e li trasforma in azioni di *gamification*.

### Mobility Milestones

I **Mobility Milestones** sono obiettivi giornalieri che premiano gli utenti per le loro scelte di trasporto sostenibile. Il sistema supporta:

- **Tre metriche**: minuti di viaggio sostenibile, chilometri percorsi e CO₂ evitata.
- **Livelli target multipli**: fino a dieci soglie progressive per metrica, che abilitano un riconoscimento graduale — da obiettivi per principianti a sfide avanzate.
- **Tracciamento per tipo di trasporto**: rilevamento delle specifiche modalità di trasporto sostenibile (trasporto pubblico, bicicletta, camminata).
- **Riscatto dei milestone**: i milestone raggiunti possono essere riscattati per attivare ricompense all'interno del sistema di *gamification*.

### Tracciamento della mobilità e metriche di sostenibilità

Il sistema sottostante di **tracciamento della mobilità** registra i singoli viaggi con dati dettagliati:

- **Rilevamento del viaggio**: identificazione automatica della modalità di trasporto e della durata.
- **Distanza e percorso**: lunghezza del viaggio e tracciato geografico (GeoJSON).
- **Impatto ambientale**: CO₂ emessa e CO₂ evitata rispetto all'uso dell'automobile.
- **Qualità dei dati**: flag integrati per il rilevamento errato, a garanzia dell'accuratezza del tracciamento.

Questi dati alimentano il sistema di *gamification* più ampio attraverso i log delle attività, contribuendo a missioni, classifiche e accumulo di ricompense.

## Modello di origine dei contenuti

Un principio di progettazione trasversale in AWorld Lab è il **modello di origine dei contenuti**, applicato in modo coerente ad attività, Learning Path, Learning Group, slide e quiz.

### Origini: Catalog, Custom e AI

Ogni entità di contenuto supporta fino a tre tipologie di origine:

- **Catalog**: contenuti predefiniti e validati dalla libreria curata di AWorld Lab. Ideale per un deployment rapido.
- **Custom**: contenuti creati dal cliente, personalizzati in base alle proprie esigenze e alla propria identità di marca.
- **AI**: contenuti generati dal sistema AI di AWorld Lab, che consente la creazione rapida di Learning Path, slide e quiz a partire da temi e obiettivi forniti dal cliente.

### Sincronizzazione del catalogo

I contenuti provenienti dal catalogo possono essere **sincronizzati automaticamente** con il catalogo di AWorld Lab, garantendo ai clienti di beneficiare di aggiornamenti, correzioni e miglioramenti senza intervento manuale. I clienti mantengono la possibilità di disabilitare la sincronizzazione e gestire i contenuti in modo indipendente.

> Il modello di origine dei contenuti consente ai clienti di iniziare rapidamente con i contenuti del catalogo, accelerare la creazione con l'AI e personalizzare progressivamente l'esperienza — il tutto all'interno dello stesso sistema unificato.