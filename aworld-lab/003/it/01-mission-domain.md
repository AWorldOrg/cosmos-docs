Il sistema di mission trasforma le azioni degli utenti in obiettivi strutturati. Risponde a domande come _"Questo utente ha completato 10 quiz questa settimana?"_ oppure _"Il team marketing ha collettivamente terminato 50 attività questo mese?"_

> Questa sezione copre il modello di configurazione completo: gerarchie di entità, logica di matching, modalità di assegnazione e gestione del ciclo di vita. È rilevante per chiunque configuri le mission tramite la dashboard o le integri via API. Per una panoramica di alto livello su cosa fanno le mission, vedi i Fondamenti della Gamification. Per i pattern condivisi tra tutti i domini (espressioni JsonLogic, timeframe, entity matching), vedi i Pattern Trasversali.

Il dominio è costruito attorno a quattro entità che formano una gerarchia chiara:

```
MissionConfiguration  (cosa conta e come contarlo)
      │
      └──▶ MissionRule  (quando, per chi e come assegnare)
                │
                └──▶ Mission  (istanza di tracciamento per utente o per gruppo)
                        │
                        └──▶ MissionLog  (traccia di audit immutabile dei progressi)
```

## Mission Configuration

Una **Mission Configuration** definisce _quali azioni degli utenti contano_ ai fini di una mission e _come vengono misurati i progressi_. È il template che specifica la logica di matching, le regole di incremento e gli obiettivi di completamento.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `missionConfigurationId` | nanoid | Identificatore univoco |
| `name` | string | Riferimento leggibile (es. "Rispondi correttamente a 10 Quiz") |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Se le mission tracciano un singolo utente o un gruppo |
| `matchType` | `INSTANCE` \| `ENTITY` \| `TAG` | Come abbinare gli eventi in arrivo |
| `matchEntity` | `Activity` \| `Quiz` \| `Tag` | Quale tipo di entità monitorare |
| `matchEntityId` | string? | ID specifico dell'entità o del tag (obbligatorio per `INSTANCE` e `TAG`) |
| `matchCondition` | JsonLogic | Logica di matching aggiuntiva valutata a runtime |
| `incrementExpression` | JsonLogic | Quanto progresso aggiunge ogni evento corrispondente |
| `targetAmountExpression` | JsonLogic | La soglia di completamento |
| `origin` | `CATALOG` \| `CUSTOM` | Dove è stata creata questa configurazione |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (1–10) |

### Match Types

- **`INSTANCE`**: Corrisponde a un'entità _specifica_. Esempio: completare l'attività `abc123`. Richiede `matchEntityId`.
- **`ENTITY`**: Corrisponde a _qualsiasi_ entità di quel tipo. Esempio: completare qualsiasi quiz.
- **`TAG`**: Corrisponde a qualsiasi entità taggata con il tag indicato. Esempio: completare qualsiasi attività taggata `sustainability`. Richiede `matchEntityId` (l'ID del tag).

### Espressioni

I tre campi expression sono ciò che rende flessibili le mission configuration:

**`matchCondition`** filtra quali eventi sono idonei. Riceve `{ mission }` come contesto e deve restituire un valore truthy affinché l'evento venga conteggiato. Esempio: contare solo i quiz con outcome `SUCCESS`.

**`incrementExpression`** definisce quanto progresso aggiunge ogni evento idoneo. Riceve `{ user, event }` e deve restituire un numero. Un valore statico come `1` significa "aggiungi 1 per evento". Un'espressione condizionale può assegnare importi diversi in base al contesto — ad esempio, assegnare `2` per i quiz difficili e `1` per quelli facili.

**`targetAmountExpression`** definisce quando la mission è completata. Riceve `{ user, mission }` e deve restituire un numero. Un valore statico `10` significa "completa dopo 10 incrementi". Un'espressione dinamica può impostare obiettivi diversi per utente — ad esempio, un obiettivo più alto per gli utenti premium.

> **Vincolo**: Quando un'espressione JsonLogic restituisce `null`, stringa vuota o `NaN`, il sistema utilizza il valore predefinito `1` sia per il calcolo dell'incremento che dell'obiettivo.

## Mission Rule

Una **Mission Rule** definisce _quando e per chi_ vengono assegnate le mission. Ogni regola fa riferimento a una o più Mission Configuration (tramite un pool o una condizione di matching) e controlla come tali configurazioni vengono istanziate come mission effettive per gli utenti.

### Campi principali

| Field | Type | Description |
|-------|------|-------------|
| `missionRuleId` | nanoid | Identificatore univoco |
| `name` | string | Nome leggibile |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Deve corrispondere alle configurazioni referenziate |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Stato del ciclo di vita |
| `assignmentMode` | `LAZY` \| `EVENT` \| `DISABLED` | Come vengono assegnate le mission agli utenti |
| `usersMatchCondition` | JsonLogic? | A quali utenti si applica questa regola (obbligatorio per INDIVIDUAL) |
| `missionsMatchCondition` | JsonLogic | Filtra quali configurazioni istanziare |
| `missionConfigurationsPool` | string[]? | Lista esplicita di ID configurazione da utilizzare (alternativa al matching) |

### Modalità di assegnazione

La modalità di assegnazione determina _come_ e _quando_ vengono create le mission per gli utenti:

**`LAZY`**: Le mission vengono create on-demand quando un utente esplora le mission disponibili. Se l'utente soddisfa le condizioni della regola, la mission viene generata in tempo reale. Ideale per esperienze guidate dalla scoperta in cui gli utenti scelgono quali mission perseguire.

**`EVENT`**: Le mission vengono assegnate automaticamente quando si verifica un evento corrispondente — ad esempio, assegnare una mission di follow-up quando l'utente completa un Learning Path. È reattivo e in tempo reale.

**`DISABLED`**: Non vengono effettuate assegnazioni. Utilizzato per disattivare una regola senza eliminarla.

### Campi per la modalità EVENT

Quando `assignmentMode` è `EVENT`, quattro campi aggiuntivi diventano obbligatori:

| Field | Type | Description |
|-------|------|-------------|
| `eventMatchType` | `INSTANCE` \| `ENTITY` \| `TAG` | Come abbinare l'evento scatenante |
| `eventMatchEntity` | `Activity` \| `Quiz` \| `Tag` \| `User` | Quale tipo di entità attiva l'assegnazione |
| `eventMatchEntityId` | string | ID specifico dell'entità o del tag |
| `eventMatchCondition` | JsonLogic | Filtraggio aggiuntivo sull'evento |

> **Vincolo**: Tutti e quattro i campi `eventMatch*` sono obbligatori quando `assignmentMode` è `EVENT` e devono essere assenti per le altre modalità.

### Targeting utenti e mission

**`usersMatchCondition`** determina quali utenti sono idonei per questa regola. Riceve `{ user, activeMissions }` come contesto — dove `activeMissions` è la lista delle mission già assegnate all'utente. Questo consente regole come "assegna solo se l'utente non ha già 3 mission attive".

> **Vincolo**: `usersMatchCondition` è obbligatorio per le regole `INDIVIDUAL` e deve essere assente per le regole `GROUP` (l'intero gruppo è idoneo per definizione).

**`missionsMatchCondition`** filtra quali Mission Configuration devono essere istanziate. Riceve `{ user, activeMissions, mission }` dove `mission` è una configurazione candidata. Questo consente regole come "istanzia solo le configurazioni taggate con il dipartimento dell'utente".

**`missionConfigurationsPool`** è un'alternativa a `missionsMatchCondition` — una lista esplicita di ID configurazione. Quando presente, vengono considerate solo queste configurazioni.

### Intervallo temporale

| Field | Type | Description |
|-------|------|-------------|
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Se la regola è attiva a tempo indeterminato, una sola volta o in modo ricorrente |
| `timeframeStartsAt` | ISO datetime | Quando la regola inizia |
| `timeframeEndsAt` | ISO datetime? | Quando la regola termina (obbligatorio per `RANGE` e `RECURRING`) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Se utilizzare un fuso orario fisso o quello di ciascun utente |
| `timeframeTimezone` | timezone? | Il fuso orario fisso (obbligatorio quando `FIXED`) |
| `recurrence` | `DAILY` \| `WEEKLY` \| `MONTHLY` \| `CUSTOM`? | Cadenza di reset (obbligatorio per `RECURRING`) |
| `scheduleCron` | cron? | Espressione cron (obbligatorio quando la ricorrenza è `CUSTOM`) |

Per una spiegazione completa della gestione di intervalli temporali, ricorrenze e fusi orari, consultare il documento Cross-Cutting Patterns.

### Targeting per gruppo

| Field | Type | Description |
|-------|------|-------------|
| `groupTagId` | string? | Il tag che identifica il gruppo (obbligatorio per le regole `GROUP`) |

> **Vincolo**: Le regole `GROUP` richiedono `groupTagId`. Le regole `INDIVIDUAL` non devono averlo.

## Mission (assegnazione)

Una **Mission** è un'istanza di tracciamento — l'assegnazione concreta di una Mission Configuration a un utente o gruppo specifico nell'ambito di una regola specifica. Contiene il progresso attuale e l'obiettivo congelato.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `missionId` | nanoid | Identificatore univoco |
| `missionConfigurationId` | nanoid | La configurazione su cui si basa questa mission |
| `missionRuleId` | nanoid? | La regola che ha attivato questa assegnazione |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Ereditato dalla configurazione |
| `userId` | nanoid? | L'utente a cui appartiene questa mission (solo INDIVIDUAL) |
| `groupTagId` | string? | Il gruppo a cui appartiene questa mission (solo GROUP) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Stato del ciclo di vita |
| `isCompleted` | boolean? | Se l'obiettivo è stato raggiunto |
| `completedAt` | ISO datetime? | Quando la mission è stata completata |
| `currentAmount` | number | Progresso accumulato |
| `targetAmount` | number | Soglia di completamento congelata |
| `periodId` | string | Chiave di deduplicazione per le mission ricorrenti |

La mission contiene anche copie dei campi di matching e delle espressioni dalla configurazione (`matchType`, `matchEntity`, `matchEntityId`, `matchCondition`, `incrementExpression`, `targetAmountExpression`) in modo che il tracciamento dei progressi non dipenda dal fatto che la configurazione rimanga invariata.

### Tipi di mission

Le **mission INDIVIDUAL** sono assegnate a un singolo utente. Ogni utente ottiene la propria istanza di mission con tracciamento dei progressi indipendente. Quando `currentAmount >= targetAmount`, la mission viene contrassegnata come completata e smette di accettare ulteriori incrementi.

Le **mission GROUP** sono assegnate a un gruppo identificato da un tag. Tutti gli utenti del gruppo contribuiscono allo stesso `currentAmount`. A differenza delle mission individuali, le mission di gruppo **continuano a contare dopo aver raggiunto l'obiettivo** — tracciano il progresso cumulativo del gruppo senza limite.

> **Vincolo**: Le mission INDIVIDUAL richiedono `userId` e non ammettono `groupTagId`. Le mission GROUP richiedono `groupTagId` e non ammettono `userId`.

### Identificazione del periodo

Il campo `periodId` funge da chiave di deduplicazione che impedisce alla stessa regola di assegnare mission duplicate nello stesso periodo temporale:

| Timeframe | periodId Format | Example |
|-----------|----------------|---------|
| `PERMANENT` | `"PERMANENT"` | `PERMANENT` |
| `RANGE` | Orario di inizio della regola in UTC | `2025-01-01T00:00:00` |
| `RECURRING` / `DAILY` | `YYYY-MM-DD` | `2025-09-15` |
| `RECURRING` / `WEEKLY` | `YYYY-Www` | `2025-W38` |
| `RECURRING` / `MONTHLY` | `YYYY-MM` | `2025-09` |
| `RECURRING` / `CUSTOM` | Orario dell'ultimo trigger cron in UTC | `2025-09-15T06:00:00` |

Un record **MissionRuleEvaluation** viene creato ogni volta che una regola viene valutata per un utente/gruppo in un dato periodo, prevenendo assegnazioni duplicate.

### Ciclo di vita dello stato

```
    la regola assegna la mission
           │
    ┌──────▼──────┐
    │   PENDING    │ ◀── la mission inizia in futuro
    └──────┬──────┘
           │  startsAt raggiunto
           ▼
    ┌─────────────┐     currentAmount >= targetAmount
    │   ACTIVE    │ ──────────────────────────────────▶ isCompleted = true
    └──────┬──────┘     (solo INDIVIDUAL; GROUP continua a contare)
           │  endsAt raggiunto
           ▼
    ┌─────────────┐
    │   ENDED     │ ◀── intervallo temporale scaduto
    └─────────────┘
```

- **PENDING**: La mission esiste ma il suo intervallo temporale non è ancora iniziato. Il `targetAmount` non è ancora calcolato.
- **ACTIVE**: La mission accetta progressi. Alla transizione ad ACTIVE, il `targetAmount` viene calcolato da `targetAmountExpression` e congelato — modifiche successive all'espressione o al contesto utente non lo influenzano.
- **ENDED**: L'intervallo temporale è scaduto. Stato terminale.

## Mission Log

Un **Mission Log** è un record immutabile creato ogni volta che il progresso di una mission viene aggiornato. Fornisce una traccia di audit completa di quale utente ha contribuito con quale importo e quando.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `missionLogId` | nanoid | Identificatore univoco |
| `missionId` | nanoid | La mission che è stata aggiornata |
| `missionConfigurationId` | nanoid | Riferimento alla configurazione |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Tipo di mission |
| `userId` | nanoid | L'utente che ha attivato il progresso |
| `groupTagId` | nanoid? | Per le mission di gruppo |
| `amount` | number | L'incremento applicato (predefinito: 1) |
| `additionalData` | record? | Contesto aggiuntivo dall'evento sorgente |

Per le mission di gruppo, il campo `userId` registra _quale_ utente del gruppo ha contribuito, mentre l'incremento si applica al `currentAmount` condiviso.

## Come vengono assegnate le mission

Quando si verifica un'azione utente (completamento di un'attività, superamento di un quiz, ecc.), il sistema segue percorsi diversi a seconda della modalità di assegnazione:

### Flusso in modalità EVENT

1. Il sistema sorgente (Activity, Quiz, ecc.) pubblica un evento.
2. Il motore delle mission interroga tutte le regole `ACTIVE` con `assignmentMode: EVENT` che corrispondono al tipo di entità e all'ID dell'evento.
3. Per ogni regola corrispondente:
   - La `eventMatchCondition` viene valutata rispetto ai dati dell'evento.
   - La `usersMatchCondition` viene valutata rispetto all'utente (per INDIVIDUAL) o saltata (per GROUP).
   - La `missionsMatchCondition` (o `missionConfigurationsPool`) determina quali configurazioni istanziare.
   - Un controllo `MissionRuleEvaluation` previene assegnazioni duplicate nello stesso periodo.
4. Le nuove assegnazioni di Mission vengono create in batch.

### Flusso in modalità LAZY

1. Un utente esplora le mission disponibili (es. apre la schermata delle mission).
2. Il sistema interroga tutte le regole `ACTIVE` con `assignmentMode: LAZY`.
3. Per ogni regola, viene eseguita la stessa catena di valutazione: idoneità utente → matching configurazione → controllo deduplicazione.
4. Le mission idonee vengono create al volo e restituite all'utente.

### Rimappatura degli eventi sorgente

Gli eventi sorgente vengono rimappati ai tipi di entità prima della valutazione:

| Source Event | Maps To |
|-------------|---------|
| `ActivityLog` | `Activity` |
| `QuizLog` | `Quiz` |
| Others | Pass through |

## Come vengono tracciati i progressi

Quando un utente esegue un'azione che potrebbe contare ai fini di una mission:

1. Il sistema interroga tutte le mission `ACTIVE` e non completate che corrispondono all'evento (per `matchType`, `matchEntity`, `matchEntityId`).
2. Per ogni mission corrispondente, la `matchCondition` viene valutata rispetto al contesto dell'evento.
3. Se la condizione è soddisfatta, la `incrementExpression` viene valutata per determinare quanto aggiungere.
4. Il `currentAmount` della mission viene incrementato atomicamente.
5. Viene creata una voce immutabile `MissionLog`.
6. Per le mission INDIVIDUAL: se `currentAmount >= targetAmount`, la mission viene contrassegnata come completata (`isCompleted: true`, `completedAt` impostato).
7. Per le mission GROUP: il contatore prosegue indipendentemente dal raggiungimento dell'obiettivo.

### Idempotenza

L'aggiornamento del contatore è idempotente — se lo stesso evento viene elaborato due volte (a causa di tentativi ripetuti o consegna at-least-once), il `currentAmount` della mission viene incrementato una sola volta. Questo viene garantito tramite una chiave di idempotenza basata sull'ID dell'evento.

Il completamento della mission utilizza un aggiornamento condizionale del database che imposta `isCompleted: true` solo se precedentemente era `false`, prevenendo il doppio completamento.

## Esempio: configurazione completa

Consideriamo un'azienda che vuole creare una sfida quiz settimanale: _"Completa 5 quiz con punteggio sufficiente ogni settimana."_

### Passo 1: Mission Configuration

```json
{
  "missionConfigurationId": "mc_quiz_weekly",
  "name": "Weekly Quiz Challenge",
  "missionType": "INDIVIDUAL",
  "matchType": "ENTITY",
  "matchEntity": "Quiz",
  "matchCondition": { "===": [{ "var": "event.outcome" }, "SUCCESS"] },
  "incrementExpression": 1,
  "targetAmountExpression": 5,
  "defaultLang": "en",
  "langs": ["en", "it"]
}
```

Questo dice: _conta qualsiasi completamento di quiz in cui l'outcome è SUCCESS, aggiungi 1 per evento, completa a 5._

### Passo 2: Mission Rule

```json
{
  "missionRuleId": "mr_quiz_weekly",
  "name": "Weekly Quiz Rule",
  "missionType": "INDIVIDUAL",
  "assignmentMode": "LAZY",
  "usersMatchCondition": true,
  "missionsMatchCondition": true,
  "missionConfigurationsPool": ["mc_quiz_weekly"],
  "timeframeType": "RECURRING",
  "timeframeStartsAt": "2025-01-06T00:00:00Z",
  "timeframeEndsAt": "2025-12-31T23:59:59Z",
  "timeframeTimezoneType": "USER",
  "recurrence": "WEEKLY",
  "defaultLang": "en",
  "langs": ["en"]
}
```

Questo dice: _ogni settimana, rendi questa mission disponibile a tutti gli utenti (LAZY — la vedono quando esplorano le mission). Usa il fuso orario locale di ciascun utente per i confini settimanali._

### Passo 3: cosa succede a runtime

1. **Lunedì**: L'utente apre la schermata delle mission. La regola LAZY viene valutata. Viene creata una nuova Mission:
   - `periodId: "2025-W38"`, `state: "ACTIVE"`, `currentAmount: 0`, `targetAmount: 5`
2. **Martedì**: L'utente completa un quiz con outcome SUCCESS. La `matchCondition` è soddisfatta. `incrementExpression` restituisce 1. La mission diventa `currentAmount: 1`.
3. **Mercoledì**: L'utente completa un quiz ma non lo supera. La `matchCondition` restituisce falso (l'outcome non è SUCCESS). Nessun incremento.
4. **Venerdì**: L'utente completa altri 4 quiz con successo. La mission raggiunge `currentAmount: 5`, `isCompleted: true`.
5. **Lunedì successivo**: Inizia un nuovo periodo (`2025-W39`). La regola LAZY crea una nuova mission con `currentAmount: 0`.

### Alternativa: mission di team basata su evento

```json
{
  "missionRuleId": "mr_team_event",
  "name": "Team Onboarding Challenge",
  "missionType": "GROUP",
  "groupTagId": "department:engineering",
  "assignmentMode": "EVENT",
  "eventMatchType": "ENTITY",
  "eventMatchEntity": "Activity",
  "eventMatchEntityId": "activity_onboarding",
  "eventMatchCondition": true,
  "missionsMatchCondition": true,
  "missionConfigurationsPool": ["mc_team_onboarding"],
  "timeframeType": "RANGE",
  "timeframeStartsAt": "2025-09-01T00:00:00Z",
  "timeframeEndsAt": "2025-09-30T23:59:59Z",
  "timeframeTimezoneType": "FIXED",
  "timeframeTimezone": "Europe/Rome"
}
```

Questo dice: _quando un utente qualsiasi completa l'attività di onboarding, assegna una mission di gruppo al dipartimento di ingegneria. La mission traccia il progresso collettivo dal 1 al 30 settembre, ora di Roma._

## Riepilogo dei concetti chiave

| Concetto | Scopo |
|----------|-------|
| **MissionConfiguration** | Definisce _quali eventi contano_ e _come misurare i progressi_ (matching + espressioni) |
| **MissionRule** | Definisce _quando, per chi e come_ vengono assegnate le mission (intervallo temporale + targeting + modalità) |
| **Mission** | Istanza di tracciamento per utente o per gruppo con obiettivo congelato e progresso in tempo reale |
| **MissionLog** | Traccia di audit immutabile di ogni evento di progresso |
| **assignmentMode** | Come vengono create le mission: `LAZY` (on-demand), `EVENT` (reattivo), `DISABLED` (disattivato) |
| **missionType** | `INDIVIDUAL` (un utente, si ferma all'obiettivo) o `GROUP` (contatore condiviso, continua) |
| **matchType** | Come vengono abbinati gli eventi: `INSTANCE` (specifico), `ENTITY` (qualsiasi del tipo), `TAG` (per tag) |
| **periodId** | Chiave di deduplicazione che garantisce una mission per regola per periodo temporale |
| **targetAmount** | Congelato quando la mission diventa ACTIVE — immune a modifiche successive della configurazione |
| **MissionRuleEvaluation** | Traccia quali combinazioni regola+periodo sono state valutate, prevenendo duplicati |

## Domini correlati

- **Dominio Reward e Currency**: il completamento delle missioni è uno degli eventi chiave che attiva le regole di ricompensa per l'erogazione di valuta virtuale.
- **Dominio Learning Content**: il completamento di learning path e quiz può alimentare il progresso delle missioni tramite entity matching.
- **Dominio Leaderboard**: le classifiche classificano gli utenti in base alla valuta virtuale accumulata, che spesso proviene dalle ricompense delle missioni.
- **Dominio Streak**: le azioni di completamento delle missioni possono alimentare i contatori delle streak.
- **Cross-Cutting Patterns**: espressioni JsonLogic, entity matching (INSTANCE/ENTITY/TAG), timeframe e pattern del ciclo di vita degli stati utilizzati in tutto questo dominio.
