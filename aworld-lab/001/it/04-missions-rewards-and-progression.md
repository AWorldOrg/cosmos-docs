Questa sezione copre il **motore** del sistema di *gamification* di AWorld Lab: le regole, le ricompense e le meccaniche di progressione che danno significato alle azioni degli utenti. Le missioni trasformano le attività in obiettivi, le streak premiano la costanza nel tempo, le valute virtuali quantificano il progresso e le regole di ricompensa automatizzano gli incentivi — creando un ciclo di *engagement* completo. Per le attività e i contenuti fondamentali che alimentano queste meccaniche, fare riferimento alla documentazione sulle attività e i contenuti.

## Missioni

Le **missioni** sono il meccanismo principale per trasformare le attività degli utenti in obiettivi strutturati. Una missione definisce un **target** — un numero specifico o una combinazione di attività da completare — e traccia il progresso verso quel target. Quando il target viene raggiunto, la missione è completata e vengono attivate le ricompense e i riconoscimenti associati.

### Tipologie di missioni: individuali e di gruppo

AWorld Lab supporta due tipologie di missioni:

- **Missioni individuali**: assegnate a un singolo utente, tracciano il progresso personale verso l'obiettivo.
- **Missioni di gruppo**: assegnate a un gruppo di utenti identificati da un tag condiviso, tracciano il **progresso collettivo** di tutti i membri del gruppo. Questo abilita sfide di squadra in cui la collaborazione guida il completamento.

### Ciclo di vita delle missioni: stati e intervalli temporali

Ogni missione segue un **ciclo di vita basato su stati**:

- **Pending**: la missione esiste ma la sua data di inizio non è ancora arrivata.
- **Active**: la missione è nel suo intervallo temporale e accetta progressi.
- **Ended**: l'intervallo temporale della missione è scaduto.

Le missioni supportano tre **configurazioni temporali**:

- **Permanent**: nessuna data di fine — la missione resta attiva a tempo indeterminato.
- **Range**: una data di inizio e fine fissa — ideale per campagne a tempo limitato.
- **Recurring**: missioni che si azzerano e si ripetono a intervalli regolari — perfette per cicli di *engagement* settimanali o mensili.

### Matching delle missioni e tracciamento del progresso

Il sistema delle missioni utilizza un **motore di matching** flessibile per determinare quali azioni degli utenti contano ai fini del progresso. Ogni missione specifica:

- **Match type**: se confrontare un'istanza specifica di attività, qualsiasi attività di un certo tipo, o attività associate a un tag specifico.
- **Match entity**: il tipo di azione tracciabile da monitorare — attività, quiz o tag.
- **Match condition**: un'espressione configurabile che filtra quali eventi si qualificano (ad es. "solo quiz con esito positivo" o "solo attività con un tag specifico").

Quando si verifica un evento corrispondente, il sistema applica un'**espressione di incremento** per calcolare quanto progresso aggiungere, e confronta il risultato con un'**espressione target** che determina la soglia di completamento.

Questa architettura abilita missioni che spaziano da semplici ("Completa 10 attività") a sofisticate ("Accumula 500 punti da quiz con difficoltà superiore a 3, nel mese corrente").

Ogni aggiornamento del progresso viene registrato nel **Mission Log**, fornendo un audit trail completo di come la missione è stata completata.

### Regole delle missioni e modalità di assegnazione

Invece di assegnare manualmente le missioni ai singoli utenti, AWorld Lab fornisce un **motore di regole** che automatizza la distribuzione delle missioni:

- Le **Mission Configuration** fungono da template, definendo la logica di matching, le regole di progresso e i metadati per una tipologia di missione.
- Le **Mission Rule** determinano come e quando questi template vengono istanziati come missioni effettive per gli utenti.

Le regole supportano diverse **modalità di assegnazione**:

- **Lazy**: le missioni vengono create on-demand quando un utente esplora le missioni disponibili. Se l'utente soddisfa le condizioni della regola, la missione viene generata in tempo reale. Ideale per esperienze basate sulla scoperta.
- **Event**: le missioni vengono assegnate automaticamente quando si verifica un evento specifico — ad esempio, assegnando una missione di follow-up quando l'utente completa un Learning Path. Combinato con timeframe ricorrenti, consente anche il deployment in stile campagna a intervalli predeterminati.

Ogni regola include **condizioni di targeting utente** che determinano quali utenti sono idonei, consentendo una segmentazione precisa per tag, attributi o comportamento.

### Regole configurabili con JSONLogic

Il sistema di missioni di AWorld Lab è alimentato da un **linguaggio di espressioni flessibile** per la definizione di condizioni, incrementi e target. Questo significa che:

- Le **match condition** possono filtrare gli eventi per qualsiasi combinazione di attributi — tipo di entità, esito, tag, difficoltà o metadati personalizzati.
- Le **espressioni di incremento** possono assegnare diversi valori di progresso in base al contesto — ad esempio, assegnando un progresso doppio per attività completate durante un periodo promozionale.
- Le **espressioni target** possono calcolare dinamicamente gli obiettivi — ad esempio, impostando il target in base al livello dell'utente o alla dimensione del gruppo.

Questa configurabilità consente ai clienti di progettare meccaniche di *engagement* complesse senza modifiche al codice, adattando le missioni a qualsiasi contesto di business attraverso la sola configurazione.

### Missioni di gruppo

Le **missioni di gruppo** abilitano sfide collaborative in cui più utenti contribuiscono verso un obiettivo condiviso. La missione viene assegnata a un **tag di gruppo**, e ogni azione qualificante di qualsiasi utente nel gruppo incrementa il contatore condiviso.

Questo sblocca scenari di *engagement* basati sul team:

- **Sfide tra dipartimenti**: i team all'interno di un'organizzazione competono per completare il maggior numero di attività.
- **Obiettivi di community**: un'intera comunità di utenti lavora verso un traguardo collettivo.
- **Collaborazione basata su eventi**: i partecipanti a una conferenza o campagna uniscono i propri progressi verso un target comune.

Il progresso delle missioni di gruppo viene tracciato per singolo utente nel Mission Log, consentendo visibilità sia sui contributi individuali che sui risultati collettivi.

## Valute virtuali

Il sistema a punti di AWorld Lab è costruito su un **modello multi-valuta** che va oltre il semplice accumulo di punti. Ogni workspace può definire **molteplici valute virtuali**, ciascuna con uno scopo strategico differente — dalla progressione basata sull'esperienza ai crediti spendibili.

### Modello multi-valuta

Una valuta virtuale è definita da:

- **Nome e icona**: identità visuale della valuta.
- **Vincoli di saldo**: limiti opzionali di saldo minimo e massimo per controllare l'economia.
- **Origine**: le valute possono provenire dal **catalogo** di AWorld Lab (preconfigurate) o essere definite in modo **personalizzato** dal cliente.
- **Supporto multilingua**: nomi e descrizioni delle valute localizzati per mercati differenti.

> Una configurazione tipica utilizza due valute: **punti esperienza** che guidano le classifiche in *leaderboard* e **crediti** che vengono guadagnati dal completamento delle missioni e riscattabili per ricompense. Tuttavia, i clienti possono definire qualsiasi numero di valute per adattarsi al proprio modello di *engagement*.

### Saldo virtuale e transazioni

Ogni utente mantiene un **saldo virtuale** per valuta, che traccia:

- **Importo totale**: il saldo cumulativo.
- **Importo disponibile**: il saldo disponibile per la spesa, escludendo transazioni in sospeso o congelate.

Tutte le variazioni di saldo vengono elaborate tramite **transazioni virtuali**, che forniscono un registro completo di ogni credito e debito con qualità da standard finanziario:

- **Direzione**: credito (aggiunta al saldo) o debito (sottrazione dal saldo).
- **Iniziatore**: chi o cosa ha causato la transazione — una **regola di ricompensa**, una **regola di streak**, un processo di **sistema**, un'azione **admin** o l'**utente** stesso.
- **Controparte**: l'altra parte nella transazione (utente o sistema).

### Ciclo di vita delle transazioni e automazione

Ogni transazione segue un **ciclo di vita basato su stati**:

- **Pending**: la transazione è stata creata ma non ancora finalizzata.
- **Completed**: la transazione è finalizzata e riflessa nel saldo.
- **Expired**: la transazione non è stata riscattata entro il periodo di validità.
- **Rejected**: la transazione è stata rifiutata (ad es. saldo insufficiente per un debito).

Le transazioni supportano due **modalità di riscatto**:

- **Auto**: la transazione viene immediatamente finalizzata alla creazione — tipica per l'erogazione delle ricompense.
- **Manual**: la transazione richiede un'azione esplicita da parte dell'utente o dell'admin per essere finalizzata — utile per i flussi di riscatto dei premi.

Le transazioni possono inoltre avere una **data di scadenza**, abilitando ricompense a tempo limitato che incoraggiano un *engagement* tempestivo.

### Configurazioni pratiche

Il modello multi-valuta supporta un'ampia gamma di strategie di *engagement*:

- **Orientato alla competizione**: una singola valuta esperienza guida le classifiche in *leaderboard*, senza meccanismo di spesa.
- **Orientato alle ricompense**: i crediti vengono guadagnati e spesi in premi, senza influenzare le classifiche competitive.
- **Ibrido**: i punti esperienza tracciano l'*engagement* mentre i crediti forniscono un'economia parallela per le ricompense.
- **Multi-dimensionale**: valute specializzate per diverse aree del programma — punti formazione, crediti sostenibilità, token fedeltà — ciascuna con gestione del saldo indipendente.

Ogni cliente mantiene il pieno controllo su come le valute vengono generate, distribuite e utilizzate, costruendo un'economia allineata ai propri obiettivi strategici.

## Regole di ricompensa

Le **regole di ricompensa** automatizzano la distribuzione di valuta virtuale in base alle azioni degli utenti. Quando un utente completa un'attività, termina un Quiz, raggiunge l'obiettivo di una missione o completa un Learning Path, il motore di ricompensa valuta tutte le regole applicabili e distribuisce le ricompense corrispondenti.

### Struttura delle regole e match entity

Ogni regola di ricompensa definisce:

- **Tipo di regola**: se la regola corrisponde a un'istanza specifica, a qualsiasi entità di un tipo, o a entità associate a un tag.
- **Match entity**: il tipo di azione che attiva la ricompensa — **Mission**, **Activity**, **Quiz**, **Learning Path**, **Learning Group**, **Slide** o **Tag**.
- **Match condition**: un'espressione configurabile che filtra quali eventi si qualificano per la ricompensa.
- **Ricompense**: uno o più pagamenti in valuta, ciascuno indirizzato a una specifica valuta virtuale con un importo calcolato.

Una singola regola può distribuire **molteplici ricompense** simultaneamente — ad esempio, assegnando sia punti esperienza che crediti al completamento di una missione.

### Modalità di applicazione e configurazione multi-ricompensa

Le regole operano in diverse **modalità di applicazione**:

- **Always**: la ricompensa viene assegnata ogni volta che le condizioni sono soddisfatte.
- **Fallback**: la ricompensa viene assegnata solo se nessun'altra regola ha corrisposto allo stesso evento — utile per fornire una ricompensa di base.
- **Disabled**: la regola è inattiva.

Gli importi delle ricompense vengono calcolati tramite **espressioni configurabili**, abilitando pagamenti dinamici basati sul contesto. Ad esempio, una regola potrebbe assegnare più punti per quiz con difficoltà più elevata, o crediti bonus durante un periodo promozionale.

Come altri elementi della piattaforma, le regole di ricompensa supportano sia origini da **catalogo** (precostruite) che **personalizzate**.

## Achievements: badge e livelli

Il sistema di **achievements** fornisce progressione visibile e riconoscimento, motivando gli utenti oltre i punti e le ricompense.

I **badge** sono riconoscimenti statici assegnati quando un utente raggiunge traguardi specifici — completando una serie di missioni, partecipando a un evento o registrando un certo numero di azioni. Una volta ottenuto, un badge resta nel profilo dell'utente come prova permanente del risultato raggiunto.

I **livelli** rappresentano un sistema di progressione configurabile legato alla **valuta virtuale accumulata** all'interno di una specifica linea di valuta. Man mano che gli utenti guadagnano punti, avanzano attraverso i livelli, ciascuno dei quali rappresenta un livello superiore di *engagement*. I livelli possono sbloccare nuove funzionalità, garantire l'accesso a contenuti esclusivi o fornire benefici aggiuntivi all'interno del sistema di *gamification*.

I clienti possono progettare percorsi di progressione strutturati definendo le soglie dei livelli, fornendo agli utenti obiettivi chiari e un senso visibile di avanzamento.

## Streak

Il sistema di **streak** di AWorld Lab è progettato per premiare la **costanza degli utenti nel tempo**, promuovendo la partecipazione regolare alle attività della piattaforma. A differenza di un semplice contatore di azioni consecutive, il sistema di streak traccia la frequenza con cui l'utente interagisce con il sistema all'interno di cadenze configurabili, offrendo un ricco set di meccaniche per incentivare un'interazione sostenuta.

### Concetto di streak e cadenza

Una streak rappresenta una **catena continua di engagement dell'utente** misurata secondo una cadenza definita:

- **Cadenza giornaliera**: l'utente deve eseguire un'azione qualificante ogni giorno per mantenere la streak.
- **Cadenza settimanale**: l'utente deve eseguire un'azione qualificante ogni settimana.

La **metrica** definisce cosa rappresenta il contatore della streak:

- **Giorni**: conteggio del numero di giorni consecutivi con attività.
- **Settimane**: conteggio del numero di settimane consecutive con attività.

Questa flessibilità consente ai programmi di promuovere un coinvolgimento giornaliero o cicli settimanali più rilassati, a seconda della strategia di engagement.

### Ciclo di vita e stati della streak

Ogni streak segue un **ciclo di vita basato su stati**:

- **Active**: la streak è in corso — l'utente sta rispettando i requisiti di cadenza.
- **Completed**: la streak ha raggiunto l'obiettivo definito.
- **Broken**: l'utente ha mancato la cadenza richiesta — la catena della streak è interrotta.
- **Ended**: l'intervallo temporale della regola di streak è scaduto.

Le transizioni di stato della streak vengono valutate automaticamente in base all'attività dell'utente e alla cadenza configurata, garantendo un'accuratezza in tempo reale.

### Tipologie di streak: Regular, Freeze e combined

Il sistema supporta diverse **tipologie di streak** che determinano come vengono conteggiati i periodi di engagement:

- **Regular**: solo i giorni/settimane con attività effettiva dell'utente contano per la streak.
- **Freeze**: i giorni/settimane in cui l'utente ha attivato un freeze (vedi sotto) vengono conteggiati come mantenuti.
- **Any**: sia l'attività regolare che i giorni di freeze contano — fornendo una visione combinata della continuità della streak.

### Perfect period e obiettivi

Le streak possono tracciare i **perfect period** — attività ininterrotta lungo interi periodi di calendario:

- **Perfect Week**: l'utente ha mantenuto la streak ogni giorno richiesto della settimana.
- **Perfect Month**: attività sostenuta per l'intero mese.
- **Perfect Year**: un anno intero di engagement costante.

Inoltre, le streak supportano **obiettivi multipli a soglie progressive**, creando achievements a livelli all'interno di una singola streak. Ad esempio, una streak potrebbe avere obiettivi a 7 giorni, 30 giorni e 100 giorni — ciascuno che sblocca ricompense progressivamente maggiori.

### Meccanismo di freeze della streak

Una caratteristica distintiva del sistema di streak di AWorld Lab è il **meccanismo di freeze**, che consente agli utenti di mettere temporaneamente in pausa la propria streak senza interromperla. Questo è progettato per evitare che occasionali interruzioni distruggano i progressi a lungo termine.

Il freeze funziona attraverso il **sistema di valuta virtuale**:

- Gli utenti spendono una quantità definita di valuta virtuale per attivare un freeze per un periodo.
- Il costo del freeze viene calcolato utilizzando un'**espressione configurabile**, consentendo una tariffazione dinamica — ad esempio, aumentando il costo per streak più lunghe per mantenere la sfida.
- Durante il freeze, il contatore della streak non si incrementa ma la catena viene preservata.

Questa meccanica aggiunge profondità strategica all'esperienza di engagement: gli utenti devono valutare il costo del freeze rispetto al rischio di perdere la propria streak, creando decisioni significative all'interno del sistema di *gamification*.

### Regole e configurazione delle streak

Le streak sono gestite attraverso un **sistema basato su regole** simile a quello delle missioni:

- Le **Streak Configuration** definiscono cosa conta come contributo valido — quali attività, quiz o azioni taggate mantengono la streak.
- Le **Streak Rule** determinano come le streak vengono assegnate agli utenti, con **condizioni di targeting degli utenti** per la segmentazione.

Le configurazioni utilizzano lo stesso **motore di matching** delle missioni — matching per istanza specifica, tipo di entità o tag — garantendo coerenza tra i sistemi di regole della piattaforma.

Le regole possono abilitare o disabilitare funzionalità specifiche per ogni streak:

- Tracciamento dei perfect period (settimana, mese, anno).
- Funzionalità di freeze con integrazione della valuta virtuale.
- Obiettivi a soglie progressive.

## Tag e targeting delle entità

I **tag** sono un elemento fondamentale in AWorld Lab, utilizzati su tutta la piattaforma per **categorizzazione, targeting e segmentazione**.

### Modello dei tag: namespace e variant

Ogni tag è definito da un **namespace** e un **variant**, abilitando una categorizzazione strutturata:

- **Namespace**: la categoria o il dominio (ad es. "department", "region", "tier").
- **Variant**: il valore specifico all'interno di quel namespace (ad es. "marketing", "europe", "gold").

Questa struttura consente ai clienti di creare sistemi di tag organizzati e gerarchici senza conflitti di denominazione.

### Assegnazione cross-entity dei tag

I tag possono essere assegnati virtualmente a qualsiasi entità nella piattaforma — **utenti, attività, quiz, Learning Path, Learning Group, slide, mission configuration, mission rule, streak configuration e streak rule**. Ogni assegnazione include un valore di **priorità** per l'ordinamento.

Questa flessibilità significa che un singolo tag può collegare utenti a contenuti, missioni ad attività e regole di ricompensa a contesti specifici — creando un potente tessuto di targeting attraverso l'intero sistema di *gamification*.

### Tag in missioni, ricompense e streak

I tag svolgono un ruolo cruciale nei motori di regole della piattaforma:

- **Matching delle missioni**: le missioni possono essere configurate per tracciare attività associate a tag specifici, abilitando sfide tematiche.
- **Targeting delle ricompense**: le regole di ricompensa possono corrispondere eventi per tag, applicando ricompense diverse a diverse categorie di contenuto.
- **Configurazione degli streak**: le regole degli streak possono targetizzare specifici segmenti di utenti in base ai tag.
- **Segmentazione degli utenti**: i tag sugli utenti abilitano missioni mirate ai gruppi, *leaderboard* di community e percorsi di *engagement* differenziati.

## *Gamification* event-driven

Le meccaniche di *gamification* di AWorld Lab sono connesse attraverso un'**architettura event-driven** che assicura che ogni azione dell'utente si propaghi automaticamente attraverso l'intero sistema.

### Flusso degli eventi

Quando un utente esegue un'azione — completare un'attività, terminare un quiz, raggiungere il target di una missione — la piattaforma genera un **evento** che fluisce attraverso una pipeline di elaborazione:

1. L'azione viene registrata come voce di log (Activity Log, Quiz Log, ecc.).
2. La voce di log genera un evento che viene instradato a tutti gli handler pertinenti.
3. Ogni handler valuta l'evento rispetto alle proprie regole e applica le meccaniche appropriate.

### Come gli eventi connettono il sistema

Questo flusso di eventi crea una **reazione a catena fluida**:

- Un utente **completa un quiz** → viene creato un Activity Log.
- Il **motore delle missioni** valuta se l'azione conta ai fini di qualsiasi missione attiva → il progresso della missione viene aggiornato.
- Se una missione viene **completata**, viene creato un Mission Log → questo attiva il motore di ricompensa.
- Il **motore di ricompensa** valuta le regole di ricompensa → la valuta virtuale viene accreditata sul saldo dell'utente.
- Il **motore degli streak** valuta se l'azione estende lo streak dell'utente → il conteggio dello streak viene aggiornato.
- Le **classifiche in *leaderboard*** vengono ricalcolate in base ai saldi di valuta aggiornati.

Questa architettura significa che i clienti devono solo configurare le regole — la piattaforma gestisce l'orchestrazione in tempo reale automaticamente, assicurando che ogni azione venga riconosciuta e ricompensata senza intervento manuale.
