Il sistema di streak traccia il coinvolgimento degli utenti nel tempo. Risponde a domande come _"Questo utente è stato attivo ogni giorno negli ultimi 30 giorni?"_ o _"Quante settimane consecutive questo utente ha completato almeno un quiz?"_

Questa sezione copre il modello completo delle streak: configurazione e matching, dimensioni di cadenza e metrica, tracciamento degli obiettivi, meccanismo di freeze e sistema dei record. È rilevante per chiunque configuri streak di engagement o le integri via API. Per una panoramica di alto livello, vedi i Fondamenti della Gamification. Per i pattern condivisi (espressioni JsonLogic, timeframe, entity matching), vedi i Pattern Trasversali.

Il dominio è costruito attorno a tre entità che formano una chiara gerarchia:

```
StreakConfiguration  (cosa conta)
      │
      └──▶ StreakRule  (le regole del gioco)
                │
                └──▶ Streak  (record di tracciamento per utente)
```

## Streak Configuration

Una **Streak Configuration** definisce _quali azioni dell'utente contano_ per una streak. È il livello di matching che collega gli eventi del dominio (completamento di un'attività, terminare un quiz, ecc.) al sistema di streak.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `streakConfigurationId` | nanoid | Identificatore univoco |
| `matchType` | `INSTANCE` \| `ENTITY` \| `TAG` | Come abbinare gli eventi in arrivo |
| `matchEntity` | `Mission` \| `Activity` \| `Quiz` \| `Tag` | Quale tipo di entità monitorare |
| `matchEntityId` | string? | ID specifico dell'entità o del tag (obbligatorio per `INSTANCE` e `TAG`) |
| `matchCondition` | JsonLogic | Logica di matching aggiuntiva valutata a runtime |

### Tipi di Match

- **`INSTANCE`**: Corrisponde a un'entità _specifica_. Esempio: completare l'attività `abc123`. Richiede `matchEntityId`.
- **`ENTITY`**: Corrisponde a _qualsiasi_ entità di quel tipo. Esempio: completare qualsiasi quiz.
- **`TAG`**: Corrisponde a qualsiasi entità taggata con il tag indicato. Esempio: completare qualsiasi attività taggata `christmas`. Richiede `matchEntityId` (l'ID del tag).

È qui che risiede la flessibilità. Combinando il matching `TAG` con espressioni JsonLogic in `matchCondition`, è possibile creare streak mirate come _"solo attività a tema natalizio eseguite a dicembre"_ o _"quiz con difficoltà >= 3"_.

## Streak Rule

Una **Streak Rule** definisce _le regole del gioco_: con quale frequenza l'utente deve agire, per quanto tempo, quali obiettivi tracciare e cosa succede quando salta un periodo. Ogni regola fa riferimento a una Streak Configuration tramite `streakConfigurationId`.

### Campi principali

| Field | Type | Description |
|-------|------|-------------|
| `streakRuleId` | nanoid | Identificatore univoco |
| `streakConfigurationId` | string | Riferimento alla Streak Configuration |
| `name` | string | Nome leggibile |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Stato del ciclo di vita |
| `usersMatchCondition` | JsonLogic | A quali utenti si applica questa regola (valutata sul profilo utente + tag) |

### Cadenza e metrica

Questi due campi definiscono _come_ la streak conta i progressi:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cadence` | `DAY` \| `WEEK` | obbligatorio | Con quale frequenza l'utente deve essere attivo per mantenere la streak |
| `metric` | `DAYS` \| `WEEKS` | `DAYS` | Cosa rappresenta ogni incremento del contatore |

**Cadence** determina il requisito di _frequenza_:
- `DAY` = l'utente deve agire ogni giorno di calendario per mantenere la streak attiva.
- `WEEK` = l'utente deve agire almeno una volta per settimana ISO di calendario.

**Metric** determina _cosa viene contato_ nei record ITERATION e GOAL:
- `DAYS` = ogni incremento di `count` rappresenta un giorno attivo.
- `WEEKS` = ogni incremento di `count` rappresenta una settimana attiva.

Queste sono dimensioni ortogonali. Le combinazioni più comuni:

| Cadence | Metric | Significato |
|---------|--------|-------------|
| `DAY` | `DAYS` | L'utente deve agire quotidianamente; i contatori tracciano i giorni attivi |
| `WEEK` | `DAYS` (default) | L'utente deve agire settimanalmente; i contatori tracciano i giorni attivi all'interno della streak |
| `WEEK` | `WEEKS` | L'utente deve agire settimanalmente; i contatori tracciano le settimane attive consecutive |

> **Vincolo**: la cadenza `DAY` può avere solo metrica `DAYS` (o non definita). La metrica `WEEKS` ha senso solo con cadenza `WEEK`.

### Intervallo temporale

| Field | Type | Description |
|-------|------|-------------|
| `timeframeType` | `PERMANENT` \| `RANGE` | Se la regola viene eseguita a tempo indeterminato o ha una data di fine fissa |
| `timeframeStartsAt` | ISO datetime | Quando inizia la regola |
| `timeframeEndsAt` | ISO datetime? | Quando termina la regola (obbligatorio per `RANGE`) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Se utilizzare un fuso orario fisso o il fuso orario personale di ciascun utente |
| `timeframeTimezone` | timezone? | Il fuso orario fisso (obbligatorio quando `timeframeTimezoneType` è `FIXED`) |

L'impostazione del fuso orario è fondamentale per determinare i confini dei periodi. Con il fuso orario `USER`, un utente a Tokyo e un utente a Londra avranno confini di "giorno" diversi, garantendo equità indipendentemente dalla posizione.

### Obiettivi target

| Field | Type | Description |
|-------|------|-------------|
| `goalTargets` | number[]? | Traguardi che l'utente può raggiungere (es. `[7, 30, 100, 365]`) |

I goal target definiscono soglie di traguardo. Quando il conteggio cumulativo di un utente raggiunge un target, il record GOAL corrispondente viene contrassegnato come `COMPLETED`. Target multipli creano un sistema a livelli: raggiungere 7 giorni consecutivi, poi 30, poi 100, ecc. Una volta completati tutti i target per un ciclo, inizia un nuovo ciclo di obiettivi con `goalId` incrementato.

### Tracciamento periodo perfetto

| Field | Type | Description |
|-------|------|-------------|
| `perfectWeekEnabled` | boolean | Traccia se l'utente è stato attivo ogni giorno della settimana |
| `perfectMonthEnabled` | boolean | Traccia se l'utente è stato attivo ogni giorno/settimana del mese |
| `perfectYearEnabled` | boolean | Traccia se l'utente è stato attivo ogni giorno/settimana dell'anno |

Questi booleani abilitano un tracciamento aggiuntivo sui record di calendario (WEEK, MONTH, YEAR). Una "settimana perfetta" significa che l'utente è stato attivo tutti e 7 i giorni (per cadenza DAY) o non ha saltato alcun periodo richiesto.

### Impostazioni di freeze

| Field | Type | Description |
|-------|------|-------------|
| `freezeEnabled` | boolean | Se gli utenti possono spendere valuta virtuale per preservare una streak |
| `freezeVirtualCurrencyId` | string? | Quale valuta virtuale detrarre (obbligatorio quando il freeze è abilitato) |
| `freezeCostExpression` | JsonLogic? | Espressione per calcolare il costo del freeze (riceve il contesto `{ user, streak }`) |

Quando una streak sta per interrompersi (lo scheduler di manutenzione rileva un periodo mancato), il sistema può detrarre automaticamente valuta virtuale per "congelare" la streak invece di interromperla. Il costo è dinamico tramite JsonLogic — ad esempio, il costo potrebbe aumentare con streak più lunghe.

## Streak (Record)

Uno **Streak** è un record DynamoDB che traccia un contatore specifico per un utente specifico sotto una regola specifica. Il concetto chiave è che **una singola azione dell'utente genera simultaneamente molteplici record streak** — ciascuno traccia una dimensione diversa della stessa streak.

### Campi del record

| Field | Type | Description |
|-------|------|-------------|
| `streakId` | nanoid | Identificatore univoco del record (generato automaticamente alla prima scrittura) |
| `userId` | string | L'utente a cui appartiene questo record |
| `streakRuleId` | string | La regola a cui appartiene questo record |
| `periodType` | enum | La finestra temporale o dimensione di tracciamento (vedi sotto) |
| `periodId` | string? | Identificatore del periodo di calendario (es. `2025-09-02`, `2025-W37`) |
| `cadence` | `DAY` \| `WEEK` | Ereditato dalla regola |
| `metric` | `DAYS` \| `WEEKS` | Cosa rappresenta `count` |
| `count` | number | Contatore accumulato (incrementato atomicamente) |
| `status` | `ACTIVE` \| `COMPLETED` \| `BROKEN` \| `ENDED` | Stato del ciclo di vita |
| `kind` | `REGULAR` \| `FREEZE` \| `ANY` | Come questo periodo è stato mantenuto attivo |
| `iterationId` | number? | A quale esecuzione consecutiva appartiene (per record ITERATION) |
| `goalId` | number? | A quale ciclo di obiettivi appartiene (per record GOAL) |
| `target` | number? | La soglia del traguardo (per record GOAL) |
| `timezone` | string | Il fuso orario effettivo utilizzato per il calcolo del periodo |

### Tipi di periodo

Il campo `periodType` è ciò che rende i record streak versatili. Esistono due categorie:

#### Record di Calendario (log/storico)

Questi registrano _cosa è successo_ in una specifica finestra temporale. Servono come vista calendario e log storico.

| periodType | Esempio periodId | count | Description |
|------------|-----------------|-------|-------------|
| `DAY` | `2025-09-02` | Sempre 1 | Marcatore binario: l'utente è stato attivo in questo giorno |
| `WEEK` | `2025-W37` | Giorni o settimane attive | Quante volte l'utente è stato attivo questa settimana |
| `MONTH` | `2025-09` | Giorni o settimane attive | Quante volte l'utente è stato attivo questo mese |
| `YEAR` | `2025` | Giorni o settimane attive | Quante volte l'utente è stato attivo quest'anno |

I record di calendario vengono **sempre scritti indipendentemente dall'impostazione `metric`**. Sono ciò che la vista calendario del frontend renderizza.

- Un record `DAY` ha `status: COMPLETED` e `count: 1` — è un semplice marcatore "questo giorno è avvenuto".
- I record `WEEK`, `MONTH`, `YEAR` hanno `status: ACTIVE` e il loro `count` viene incrementato atomicamente ogni volta che l'utente agisce all'interno di quel periodo. Si accumulano.

#### Record Contatore (tracciamento progressi)

Questi tracciano i progressi cumulativi e le streak. Vengono **scritti condizionalmente in base all'impostazione `metric` della regola**.

| periodType | Utilizza | count | Description |
|------------|----------|-------|-------------|
| `ITERATION` | `iterationId` | Giorni o settimane consecutive | Traccia una singola esecuzione ininterrotta della streak. Quando la streak si interrompe e ricomincia, `iterationId` viene incrementato. |
| `GOAL` | `goalId` + `target` | Progresso verso il target | Traccia il progresso verso un traguardo specifico. Un record per target per ciclo di obiettivi. |

- Un record **ITERATION** risponde alla domanda: _"Quanto è lunga la streak ininterrotta corrente?"_ Quando count raggiunge valori elevati, l'utente ha mantenuto una streak lunga. Quando la streak si interrompe (lo status cambia in `BROKEN`), inizia una nuova iterazione con un `iterationId` incrementato.

- Un record **GOAL** risponde alla domanda: _"Quanto è vicino l'utente al raggiungimento di X giorni/settimane?"_ Per `goalTargets: [7, 30, 100]`, vengono mantenuti tre record GOAL per ciclo di obiettivi. Quando count raggiunge il target, `status` diventa `COMPLETED`. Quando tutti i target sono completati, inizia un nuovo ciclo con `goalId` incrementato.

### Ciclo di vita dello status

```
              user acts
                 │
    ┌────────────▼────────────┐
    │         ACTIVE          │◄────── initial state (ITERATION, GOAL, calendar accumulators)
    └────┬──────────────┬─────┘
         │              │
    count >= target   missed period
         │              │
         ▼              ▼
    COMPLETED        BROKEN ◄─── (unless freeze kicks in)

    Rule ends → ENDED (any status can transition to ENDED)
```

- **ACTIVE**: Il record è in fase di tracciamento e può essere incrementato.
- **COMPLETED**: Il record ha raggiunto il suo goal target (GOAL) o rappresenta un giorno di calendario completato (DAY). Non può essere ulteriormente incrementato.
- **BROKEN**: L'utente ha saltato un periodo richiesto e la streak è stata interrotta. Stato terminale per i record ITERATION.
- **ENDED**: La regola della streak è terminata (`state: ENDED`). Stato terminale.

Solo i record `ACTIVE` possono essere aggiornati — il sistema impone questo vincolo tramite condizioni DynamoDB.

### Kind

| Kind | Description |
|------|-------------|
| `REGULAR` | Il periodo è stato completato da attività reale dell'utente |
| `FREEZE` | Il periodo è stato preservato spendendo valuta virtuale |
| `ANY` | Aggregato — utilizzato per record ITERATION e GOAL che non distinguono tra periodi regolari e congelati |

## Come vengono scritti i record

Quando un utente completa un'azione che corrisponde a una streak configuration, il sistema scrive molteplici record DynamoDB in una singola transazione. L'insieme esatto dipende dalla cadenza e dalla metrica.

### Cadenza DAY

Un singolo percorso di codice (`updateDayCadenceStreakCounters`) gestisce tutto. Per ogni azione qualificante (massimo una per giorno di calendario):

| Record | periodType | metric | Scritto sempre? |
|--------|-----------|--------|-----------------|
| Voce giornaliera | `DAY` | `DAYS` | Sì (calendario) |
| Accumulatore settimanale | `WEEK` | `DAYS` | Sì (calendario) |
| Accumulatore mensile | `MONTH` | `DAYS` | Sì (calendario) |
| Accumulatore annuale | `YEAR` | `DAYS` | Sì (calendario) |
| Contatore iterazione | `ITERATION` | `DAYS` | Sì |
| Contatori obiettivo | `GOAL` | `DAYS` | Sì (uno per target) |

Per la cadenza DAY, `metric` è sempre `DAYS` — non c'è ambiguità.

### Cadenza WEEK

Due sotto-percorsi vengono eseguiti indipendentemente con le proprie protezioni di deduplicazione:

**`updateDayMetrics`** — eseguito per giorno di calendario (prima azione del giorno):

| Record | periodType | metric | Scritto quando |
|--------|-----------|--------|----------------|
| Voce giornaliera | `DAY` | `DAYS` | Sempre (calendario) |
| Contatore iterazione | `ITERATION` | `DAYS` | Solo se `rule.metric` è `DAYS` (default) |
| Contatori obiettivo | `GOAL` | `DAYS` | Solo se `rule.metric` è `DAYS` (default) |

**`updateWeekMetrics`** — eseguito per settimana di calendario (prima azione della settimana):

| Record | periodType | metric | Scritto quando |
|--------|-----------|--------|----------------|
| Voce settimanale | `WEEK` | `WEEKS` | Sempre (calendario) |
| Accumulatore mensile | `MONTH` | `WEEKS` | Sempre (calendario) |
| Accumulatore annuale | `YEAR` | `WEEKS` | Sempre (calendario) |
| Contatore iterazione | `ITERATION` | `WEEKS` | Solo se `rule.metric` è `WEEKS` |
| Contatori obiettivo | `GOAL` | `WEEKS` | Solo se `rule.metric` è `WEEKS` |

Questa suddivisione garantisce che i record ITERATION e GOAL vengano scritti esattamente una volta per la granularità temporale appropriata:
- Con `metric: DAYS` (default): l'iterazione conta i _giorni_ attivi, gli obiettivi tracciano i _giorni_ di progresso, e la protezione di dedup a livello giornaliero assicura al massimo un incremento per giorno.
- Con `metric: WEEKS`: l'iterazione conta le _settimane_ attive, gli obiettivi tracciano le _settimane_ di progresso, e la protezione di dedup a livello settimanale assicura al massimo un incremento per settimana.

### Deduplicazione

Ogni percorso di codice ha una protezione di dedup che previene il doppio conteggio:

- **Dedup giornaliera**: Prima di scrivere le metriche giornaliere, il sistema cerca un record `DAY` esistente con il `periodId` di oggi. Se trovato, l'intera funzione termina anticipatamente (nessun record scritto).
- **Dedup settimanale**: Prima di scrivere le metriche settimanali, il sistema cerca un record `WEEK` esistente con il `periodId` di questa settimana. Se trovato, l'intera funzione termina anticipatamente.

Inoltre, la funzione `prepareStreakUpdate` aggiunge condizioni DynamoDB per garantire che i record vengano scritti/aggiornati solo quando `status` è `ACTIVE` (o il record non esiste ancora).

## Pattern di accesso DynamoDB

### Partition Key

Tutti i record streak di un utente condividono la stessa partition key:

```
pk = workspaceId#<workspaceId>#userId#<userId>
```

### Sort Key (sk)

La sort key primaria codifica l'identità completa del record:

```
periodType#DAY#periodId#2025-09-02#streakRuleId#ID1#cadence#DAY#metric#DAYS#kind#REGULAR
periodType#ITERATION#iterationId#000001#streakRuleId#ID1#cadence#WEEK#metric#DAYS#kind#ANY
periodType#GOAL#goalId#000001#target#000007#streakRuleId#ID1#cadence#DAY#metric#DAYS#kind#ANY
```

Questa struttura consente query range efficienti per `periodType` e `periodId` — ad esempio, recuperare tutti i record DAY tra due date.

### Sort Key secondaria (sk2)

Un GSI (`bySk2`) riordina la sort key con `streakRuleId` al primo posto:

```
#streakRuleId#ID1periodType#DAY#periodId#2025-09-02#cadence#WEEK#metric#DAYS#kind#REGULAR
```

Questo consente query efficienti filtrate per una specifica streak rule — utilizzato internamente dalla logica di aggiornamento dei contatori per verificare le protezioni di dedup e recuperare lo stato più recente di iterazione/obiettivo.

## Gestione del ciclo di vita della streak

Un processo di manutenzione schedulato viene eseguito per ogni streak attiva per rilevare i periodi mancati:

1. Quando viene scritto un record streak, viene creata una voce **StreakSchedule** che si attiva dopo la fine del periodo corrente.
2. Lo scheduler invoca `updateStreakStatus`, che:
   - Recupera la regola della streak e l'utente.
   - Se la regola è `ENDED`, contrassegna la streak come `ENDED`.
   - Se la regola è `ACTIVE`, cerca i record streak nell'intervallo temporale previsto.
   - Se l'utente è stato attivo (record trovati per il periodo previsto), la streak continua — viene scritto un aggiornamento del contatore di tipo `FREEZE` per far avanzare la streak.
   - Se l'utente _non_ è stato attivo, il sistema verifica se l'utente può permettersi un **freeze** (detrazione di valuta virtuale). Se sì, la streak viene preservata. Se no, la streak viene contrassegnata come `BROKEN`.

## Streak multiple per utente

Un utente può avere molteplici streak attive simultaneamente, ciascuna tracciata indipendentemente:

- **Regole diverse**: Un workspace potrebbe avere una "Streak Attività Giornaliera" (cadenza DAY) e una "Streak Quiz Settimanale" (cadenza WEEK). Ciascuna genera il proprio set di record sotto un diverso `streakRuleId`.
- **Streak mirate**: Utilizzando il tipo di match `TAG` sulla configurazione, è possibile creare streak stagionali come _"Streak Attività di Natale"_ che conta solo le attività taggate con un tag specifico. Lo stesso utente potrebbe avere una streak giornaliera generale e una streak stagionale di dicembre in esecuzione in parallelo.
- **Diversi livelli di obiettivo**: Una singola regola con `goalTargets: [7, 30, 100, 365]` crea molteplici record GOAL per ciclo, ma appartengono tutti alla stessa regola.

## Esempio: set completo di record

Consideriamo un utente al giorno 15 di una streak con cadenza WEEK, `metric: DAYS` e `goalTargets: [7, 30]`:

```
# Calendar records (always written)
periodType#DAY#periodId#2025-09-15#streakRuleId#R1#cadence#WEEK#metric#DAYS#kind#REGULAR     count=1
periodType#WEEK#periodId#2025-W38#streakRuleId#R1#cadence#WEEK#metric#WEEKS#kind#REGULAR     count=3  (3rd day active this week)
periodType#MONTH#periodId#2025-09#streakRuleId#R1#cadence#WEEK#metric#WEEKS#kind#REGULAR     count=11
periodType#YEAR#periodId#2025#streakRuleId#R1#cadence#WEEK#metric#WEEKS#kind#REGULAR         count=190

# Counter records (written because metric=DAYS)
periodType#ITERATION#iterationId#000002#streakRuleId#R1#cadence#WEEK#metric#DAYS#kind#ANY    count=15  (15 days in current streak run)
periodType#GOAL#goalId#000003#target#000007#streakRuleId#R1#cadence#WEEK#metric#DAYS#kind#ANY count=7  status=COMPLETED
periodType#GOAL#goalId#000003#target#000030#streakRuleId#R1#cadence#WEEK#metric#DAYS#kind#ANY count=15 status=ACTIVE
```

In questo esempio:
- L'utente è all'iterazione #2 (la sua prima streak si è interrotta ad un certo punto, questa è la seconda esecuzione).
- Si trova al ciclo obiettivo #3 (ha completato due cicli completi di tutti i target in precedenza).
- L'obiettivo dei 7 giorni per questo ciclo è `COMPLETED`; l'obiettivo dei 30 giorni è in corso con count 15.
- I record di calendario mostrano 3 giorni attivi questa settimana, 11 questo mese, 190 quest'anno.
- I record di calendario `WEEK`, `MONTH`, `YEAR` utilizzano `metric: WEEKS` perché sono scritti da `updateWeekMetrics` (che utilizza sempre la metrica WEEKS per le sue voci di calendario).

## API di lista

L'API di lista (`GET /streaks`) supporta query per `periodType` con intervalli di date opzionali:

- **Vista calendario**: `periodType=DAY&from=2025-09-01&to=2025-09-30` restituisce tutti i marcatori giornalieri di settembre.
- **Storico iterazioni**: `periodType=ITERATION` restituisce tutte le esecuzioni della streak (ciascuna con il proprio `iterationId` e `count`).
- **Progresso obiettivi**: `periodType=GOAL` restituisce tutti i record obiettivo attraverso tutti i cicli.

Nell'ultima pagina dei risultati, l'API **sintetizza anche contatori vuoti** per qualsiasi regola attiva che non ha ancora record streak. Questo garantisce che il frontend mostri sempre tutte le regole attive, anche se l'utente non le ha ancora iniziate.

Filtri opzionali: `streakRuleId` (utilizza il GSI `bySk2` per ricerche efficienti), `iterationId`, `goalId`, `target`.

## Riepilogo dei concetti chiave

| Concetto | Scopo |
|----------|-------|
| **StreakConfiguration** | Definisce _quali eventi_ contano (matching delle entità + condizioni JsonLogic) |
| **StreakRule** | Definisce _le regole del gioco_ (cadenza, metrica, obiettivi, freeze, intervallo temporale) |
| **Streak** | Record DynamoDB per utente che tracciano ogni dimensione del progresso |
| **Cadence** | Con quale frequenza l'utente deve agire (`DAY` = giornalmente, `WEEK` = settimanalmente) |
| **Metric** | Cosa rappresentano i contatori (`DAYS` = giorni attivi, `WEEKS` = settimane attive) |
| **periodType** | La dimensione tracciata (calendario: DAY/WEEK/MONTH/YEAR; progresso: ITERATION/GOAL) |
| **Iteration** | Una singola esecuzione ininterrotta della streak; si incrementa quando la streak si interrompe e ricomincia |
| **Goal** | Un traguardo target; cicla attraverso incrementi di `goalId` man mano che i target vengono completati |
| **Kind** | Se un periodo è stato mantenuto da attività reale (`REGULAR`) o valuta virtuale (`FREEZE`) |
| **Freeze** | Detrazione automatica di valuta virtuale per prevenire l'interruzione della streak |

## Domini correlati

- **Dominio Reward e Currency**: il meccanismo di freeze detrae valuta virtuale per preservare le streak; le regole di ricompensa possono anche attivarsi su eventi correlati alle streak.
- **Dominio Mission**: il completamento delle missioni e gli eventi delle attività sono trigger comuni per le configurazioni delle streak.
- **Dominio Learning Content**: il completamento di learning path e quiz può alimentare i contatori delle streak tramite entity matching.
- **Dominio Leaderboard**: l'engagement basato sulle streak contribuisce ai punteggi delle classifiche indirettamente attraverso l'accumulo di valuta virtuale.
- **Cross-Cutting Patterns**: espressioni JsonLogic, entity matching (INSTANCE/ENTITY/TAG), timeframe e pattern del ciclo di vita degli stati utilizzati in tutto questo dominio.
