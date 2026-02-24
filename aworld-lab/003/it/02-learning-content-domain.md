Il sistema di contenuti di apprendimento gestisce esperienze educative strutturate. Risponde a domande come _"Quali percorsi di apprendimento sono assegnati a questo utente?"_, _"Quanto è progredito l'utente?"_ e _"Il prossimo percorso dovrebbe sbloccarsi ora che il precedente è completato?"_

Questa sezione copre il modello di configurazione completo: gerarchie di contenuti, assegnazione e sblocco basati su regole, gestione della visibilità e tracciamento dei progressi. È rilevante per chiunque progetti esperienze di apprendimento o le integri via API. Per una panoramica di alto livello, vedi i Fondamenti della Gamification. Per i pattern condivisi (espressioni JsonLogic, timeframe, entity matching), vedi i Pattern Trasversali.

Il dominio è costruito attorno a una gerarchia di contenitori di contenuto, un sistema di regole per l'assegnazione e il controllo degli accessi, e un livello di tracciamento dei progressi:

```
LearningPathRule  (quando, per chi e come assegnare o sbloccare)
      │
      └──▶ LearningPathAssignment  (assegnazione per utente con visibilità)
                │
                └──▶ LearningPath  (contenitore di contenuti)
                        │
                        ├──▶ Quiz
                        ├──▶ Slide
                        ├──▶ Activity
                        └──▶ LearningGroup  (contenitore annidato)
                                │
                                ├──▶ Quiz
                                ├──▶ Slide
                                └──▶ Activity
```

I progressi vengono tracciati a ogni livello:

```
LearningPathLog   (progressi per utente su un percorso di apprendimento)
LearningGroupLog  (progressi per utente su un gruppo di apprendimento)
```

## Learning Path

Un **Learning Path** è il contenitore di contenuti di livello superiore — una sequenza ordinata di elementi che l'utente completa progressivamente. Gli elementi possono essere quiz, slide, attività o gruppi di apprendimento annidati.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `learningPathId` | nanoid | Identificatore univoco |
| `title` | string | Titolo visualizzato |
| `description` | string? | Descrizione opzionale |
| `image` | URL? | Immagine in miniatura opzionale |
| `estimatedDuration` | number | Tempo stimato per il completamento |
| `items` | ItemReference[] | Lista ordinata di elementi di contenuto |
| `completionRule` | JsonLogic? | Quando il percorso è considerato completo? (predefinito: tutti gli elementi completati) |
| `outcomeRule` | JsonLogic? | Qual è il risultato? (predefinito: FAIL se un qualsiasi elemento è fallito) |
| `startRule` | JsonLogic? | Il percorso è stato avviato? (predefinito: un qualsiasi elemento ha dei progressi) |
| `origin` | `CATALOG` \| `AI` \| `CUSTOM` | Dove è stato creato questo percorso |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (1–10) |

### Elementi polimorfici

L'array `items` contiene riferimenti a contenuti di tipo diverso. Ogni riferimento ha tre campi:

| Field | Type | Description |
|-------|------|-------------|
| `itemId` | string | ID dell'entità di contenuto referenziata |
| `itemType` | enum | `activity` \| `game` \| `quiz` \| `story` \| `slide` \| `learningGroup` |
| `languages` | lang[]? | Se impostato, l'elemento appare solo in queste varianti linguistiche |

Il campo `itemType` è il discriminante — indica al sistema quale tipo di entità cercare. Un learning path può combinare qualsiasi tipo di elemento.

**Elementi specifici per lingua**: Quando `languages` è impostato (es. `["it", "de"]`), l'elemento appare solo quando l'utente visualizza il percorso in una di quelle lingue. Quando `languages` è indefinito o vuoto, l'elemento appare in tutte le lingue.

### Regole di completamento, risultato e avvio

Queste tre espressioni JsonLogic controllano come vengono calcolati i progressi aggregati. Ricevono tutte lo stesso contesto: `{ items: ItemLogStatus[] }`, dove ogni elemento ha i campi `progress` e `outcome`.

**Regola di completamento** — determina quando il percorso è considerato completo:
- Predefinito: tutti gli elementi devono avere `progress === "COMPLETE"`.
- Esempio personalizzato: il percorso è completo quando l'80% degli elementi è stato completato.

**Regola di risultato** — determina il risultato complessivo (valutata solo al completamento):
- Predefinito: `FAIL` se un qualsiasi elemento ha `outcome === "FAIL"`, altrimenti `SUCCESS`.
- Esempio personalizzato: `SUCCESS` se almeno il 70% dei quiz è stato superato.

**Regola di avvio** — determina se l'utente ha iniziato il percorso:
- Predefinito: il percorso è avviato se un qualsiasi elemento ha progressi non nulli.

> **Nota**: Queste regole vengono valutate a ogni evento di progresso di un elemento figlio. La valutazione è deterministica: dati gli stati correnti degli elementi, il risultato è sempre lo stesso.

### Retrocompatibilità

Le versioni precedenti della piattaforma utilizzavano un campo `activities` al posto di `items`, e `activityId`/`activityType` al posto di `itemId`/`itemType`. Il sistema normalizza in modo trasparente i vecchi record al momento della lettura:
- `activityId` → `itemId`
- `activityType` → `itemType`
- array `activities` → array `items`

Non è necessaria alcuna migrazione — la normalizzazione avviene in memoria.

## Learning Group

Un **Learning Group** è un contenitore annidato all'interno di un learning path. Raggruppa elementi correlati — ad esempio, una sequenza narrativa di slide seguita da un quiz.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `learningGroupId` | nanoid | Identificatore univoco |
| `type` | `story` \| `test` \| `custom` | Il tipo semantico di questo gruppo (predefinito: `custom`) |
| `title` | string | Titolo visualizzato |
| `description` | string? | Descrizione opzionale |
| `image` | URL? | Immagine opzionale |
| `estimatedDuration` | number? | Stima del tempo opzionale |
| `items` | ItemReference[] | Lista ordinata di elementi di contenuto |
| `source` | string? | Relazione semantica con un'altra entità |
| `parentId` | string? | ID dell'entità padre (per la propagazione a cascata) |
| `parentType` | `learningPath` \| `learningGroup`? | Tipo dell'entità padre |
| `completionRule` | JsonLogic? | Stesso schema del LearningPath |
| `outcomeRule` | JsonLogic? | Stesso schema del LearningPath |
| `startRule` | JsonLogic? | Stesso schema del LearningPath |
| `origin` | `CATALOG` \| `AI` \| `CUSTOM`? | Origine della creazione |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (1–10) |

### Tipi di gruppo

Il campo `type` attribuisce un significato semantico al gruppo:

**`story`** — Una sequenza narrativa. Contiene tipicamente slide e attività, organizzate come capitoli o episodi di una storia. Questo sostituisce l'entità legacy `Story` standalone.

**`test`** — Un gruppo di valutazione. Contiene tipicamente quiz. Spesso collegato a un gruppo story tramite il campo `source`, che indica quale contenuto narrativo viene valutato da questo test.

**`custom`** — Un raggruppamento generico senza significato semantico specifico. Tipo predefinito. Utilizzato per l'organizzazione arbitraria degli elementi.

### Relazioni source

Il campo `source` crea collegamenti semantici tra gruppi utilizzando un formato di chiave combinata: `"entityType#entityId"`.

Schema comune: un gruppo test referenzia il gruppo story che valuta:

```
LearningGroup (type="story", id="story_onboarding")
├── Slide: "Welcome to the company"
├── Slide: "Our values"
└── Slide: "Your first week"

LearningGroup (type="test", id="test_onboarding")
├── Quiz: "Company values quiz"
├── Quiz: "Policies quiz"
└── source: "learningGroupId#story_onboarding"
```

### Riferimento al padre

I campi `parentId` e `parentType` tracciano la posizione del gruppo nella gerarchia. Quando i progressi di un elemento figlio cambiano, l'evento include il riferimento al padre in modo che il gestore dei progressi sappia quale learning path o gruppo aggiornare a monte.

## Learning Path Rule

Una **Learning Path Rule** controlla come i percorsi di apprendimento vengono assegnati agli utenti e come viene gestito l'accesso. Esistono due tipi distinti di regole.

### Tipi di regola

**`ASSIGN`** — Crea nuove assegnazioni di percorsi di apprendimento. Una regola ASSIGN seleziona quali utenti targetizzare, quali percorsi assegnare e quale visibilità iniziale deve avere ogni assegnazione (LOCKED o UNLOCKED).

**`UNLOCK`** — Aggiorna la visibilità delle assegnazioni esistenti da LOCKED a UNLOCKED. Una regola UNLOCK monitora un evento specifico (tipicamente il completamento di un learning path) e sblocca il percorso successivo nella sequenza.

### Campi principali

| Field | Type | Description |
|-------|------|-------------|
| `learningPathRuleId` | nanoid | Identificatore univoco |
| `ruleType` | `ASSIGN` \| `UNLOCK` | Cosa fa questa regola |
| `name` | string | Nome leggibile |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Stato del ciclo di vita |
| `assignmentMode` | `LAZY` \| `EVENT` \| `DISABLED` | Come vengono attivate le assegnazioni |
| `usersMatchCondition` | JsonLogic? | Quali utenti sono idonei |

### Campi della regola ASSIGN

| Field | Type | Description |
|-------|------|-------------|
| `learningPathsPool` | nanoid[]? | Lista esplicita di ID di learning path da assegnare |
| `learningPathsMatchCondition` | JsonLogic? | Filtro dinamico per la selezione dei percorsi |
| `initialVisibilityCondition` | JsonLogic? | Determina LOCKED o UNLOCKED per ogni percorso |

> **Vincolo**: Le regole ASSIGN richiedono `learningPathsPool` (con almeno una voce) oppure `learningPathsMatchCondition`.

### Campi della regola UNLOCK

| Field | Type | Description |
|-------|------|-------------|
| `unlockLearningPathId` | nanoid? | Quale learning path sbloccare |

> **Vincolo**: Le regole UNLOCK richiedono `unlockLearningPathId` e devono utilizzare `assignmentMode: "EVENT"`.

### Modalità di assegnazione

**`LAZY`**: Le assegnazioni vengono create on-demand quando l'utente esplora i percorsi disponibili. Valido solo per le regole ASSIGN.

**`EVENT`**: Le assegnazioni vengono create (o sbloccate) quando si verifica un evento corrispondente. Obbligatorio per le regole UNLOCK. Valido sia per ASSIGN che per UNLOCK.

**`DISABLED`**: La regola è inattiva.

### Corrispondenza degli eventi

Quando `assignmentMode` è `EVENT`, questi campi diventano obbligatori:

| Field | Type | Description |
|-------|------|-------------|
| `eventMatchType` | `INSTANCE` \| `ENTITY` \| `TAG` | Come abbinare gli eventi |
| `eventMatchEntity` | `LearningPathLog` \| `User` \| `Tag` | Quale entità attiva la regola |
| `eventMatchEntityId` | string | ID specifico dell'entità o del tag |
| `eventMatchCondition` | JsonLogic | Filtro aggiuntivo sugli eventi |

Trigger di eventi comuni:
- **`LearningPathLog`** con `INSTANCE`: si attiva quando cambiano i progressi di uno specifico learning path — ideale per le regole UNLOCK che si attivano al completamento.
- **`User`** con `ENTITY`: si attiva su qualsiasi evento utente — utile per le regole ASSIGN alla creazione dell'utente.
- **`Tag`** con `TAG`: si attiva quando un tag viene assegnato a un utente — utile per le regole ASSIGN che targetizzano utenti con tag specifici.

### Intervallo temporale

Stesso schema di tutte le entità regola: `timeframeType` (PERMANENT/RANGE/RECURRING), `timeframeStartsAt`, `timeframeEndsAt`, `timeframeTimezoneType` (FIXED/USER), `recurrence` (DAILY/WEEKLY/MONTHLY/CUSTOM), `scheduleCron`. Vedi il documento sui Pattern Trasversali.

### Targeting degli utenti e dei percorsi

**`usersMatchCondition`** riceve `{ user, activeAssignments }` — dove `activeAssignments` è la lista dei percorsi già assegnati all'utente. Questo consente regole come "assegna solo se l'utente ha meno di 5 percorsi attivi".

**`learningPathsMatchCondition`** riceve `{ user, learningPath }` e restituisce se includere o meno questo percorso.

### Condizione di visibilità iniziale

La `initialVisibilityCondition` è un'espressione JsonLogic valutata una volta per ogni percorso durante l'esecuzione della regola ASSIGN. Riceve `{ learningPath, index, user }` e deve restituire `"LOCKED"` o `"UNLOCKED"`.

Se non specificata, tutti i percorsi iniziano come `UNLOCKED`.

Esempi:

```json
// Primo percorso sbloccato, gli altri bloccati (schema di sblocco sequenziale)
{
  "if": [
    { "===": [{ "var": "index" }, 0] },
    "UNLOCKED",
    "LOCKED"
  ]
}
```

```json
// Sblocca solo per gli utenti premium
{
  "if": [
    { "===": [{ "var": "user.plan" }, "premium"] },
    "UNLOCKED",
    "LOCKED"
  ]
}
```

## Learning Path Assignment

Un **Learning Path Assignment** è il record per utente che collega un utente a un learning path sotto una specifica regola. Traccia la visibilità (LOCKED/UNLOCKED) e lo stato temporale (PENDING/ACTIVE/ENDED).

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `learningPathAssignmentId` | nanoid | Identificatore univoco |
| `learningPathId` | nanoid | Quale percorso è assegnato |
| `userId` | nanoid | A chi è assegnato |
| `learningPathRuleId` | nanoid? | Quale regola ha creato questa assegnazione |
| `periodId` | string | Chiave di deduplicazione (stesso formato del `periodId` delle missioni) |
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Ambito temporale |
| `startsAt` | ISO datetime | Quando questa assegnazione diventa attiva |
| `endsAt` | ISO datetime? | Quando scade (obbligatorio per RANGE/RECURRING) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Ciclo di vita basato sul tempo |
| `visibility` | `LOCKED` \| `UNLOCKED` | Controllo degli accessi |
| `unlockedAt` | ISO datetime? | Quando il percorso è stato sbloccato |
| `unlockedByRuleId` | nanoid? | Quale regola UNLOCK ha attivato lo sblocco |
| `groupId` | string? | Per l'organizzazione nella dashboard |

### Visibilità vs. stato

Queste sono dimensioni indipendenti:

- **Stato** è basato sul tempo e automatico: PENDING → ACTIVE → ENDED.
- **Visibilità** è basata sulle regole: inizia come LOCKED o UNLOCKED (dalla regola ASSIGN), può essere cambiata in UNLOCKED da una regola UNLOCK.

Un utente può accedere a un learning path solo quando l'assegnazione è sia `ACTIVE` che `UNLOCKED`.

## Learning Path Log

Un **Learning Path Log** traccia i progressi di un utente attraverso uno specifico learning path. Esiste un record per ogni combinazione (learningPathId, userId, context) — viene aggiornato sul posto, non aggiunto in coda.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `learningPathId` | nanoid | Quale percorso |
| `userId` | nanoid | Quale utente |
| `context` | string | Contesto denominato (predefinito: `"default"`) — consente tentativi multipli |
| `lang` | lang | Lingua in cui l'utente sta lavorando |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE` | Progresso complessivo |
| `outcome` | `SUCCESS` \| `FAIL`? | Impostato solo quando progress è `COMPLETE` |
| `items` | ItemLogStatus[]? | Progressi di ogni elemento figlio |
| `currentItemId` | string? | ID dell'elemento su cui l'utente si trova attualmente |
| `currentItemType` | itemType? | Tipo dell'elemento corrente |
| `startedAt` | ISO datetime? | Quando l'utente ha iniziato |
| `completedAt` | ISO datetime? | Quando l'utente ha completato il percorso |

Ogni voce nell'array `items` ha:

| Field | Type | Description |
|-------|------|-------------|
| `itemId` | string | Riferimento all'elemento |
| `itemType` | itemType | Tipo dell'elemento |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE`? | Progresso dell'elemento |
| `outcome` | `SUCCESS` \| `FAIL`? | Risultato dell'elemento |

> **Vincolo**: Il progresso può solo avanzare: null → START → IN_PROGRESS → COMPLETE. Non torna mai indietro.

### Storico

Il log mantiene uno storico completo delle versioni. Ogni aggiornamento crea un nuovo record versionato nella tabella dello storico, mentre la tabella principale contiene sempre lo stato corrente. Questo fornisce sia ricerche rapide dello stato attuale che una traccia di audit completa.

## Learning Group Log

Un **Learning Group Log** segue lo stesso schema del Learning Path Log ma traccia i progressi all'interno di un learning group.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `learningGroupId` | nanoid | Quale gruppo |
| `userId` | nanoid | Quale utente |
| `context` | string | Contesto denominato (predefinito: `"default"`) |
| `lang` | lang | Lingua |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE` | Progresso complessivo |
| `outcome` | `SUCCESS` \| `FAIL`? | Solo al completamento |
| `items` | ItemLogStatus[]? | Progressi per elemento |
| `parentId` | string? | Learning path o gruppo padre |
| `parentType` | `learningPath` \| `learningGroup`? | Tipo dell'entità padre |
| `currentItemId` | string? | Elemento corrente |
| `startedAt` | ISO datetime? | Quando è iniziato |
| `completedAt` | ISO datetime? | Quando è stato completato |

## Come si propagano i progressi

Quando un utente completa un elemento (es. termina un quiz all'interno di un learning group), i progressi si propagano risalendo la gerarchia:

1. L'elemento figlio (quiz, slide, ecc.) registra il suo completamento.
2. Viene pubblicato un evento con `parentId` e `parentType`.
3. Il gestore dei progressi dell'entità padre riceve l'evento.
4. Il gestore aggiorna lo stato dell'elemento che ha generato l'evento nell'array `items` del padre.
5. Le regole di completamento, risultato e avvio vengono valutate rispetto agli elementi aggiornati.
6. Il log del padre viene aggiornato di conseguenza.
7. Se il padre stesso è ora completo, questo genera un altro evento risalendo la catena.

```
Quiz completed
  → event: { parentId: "lg_1", parentType: "learningGroup" }
    → LearningGroup log updated
      → event: { parentId: "lp_1", parentType: "learningPath" }
        → LearningPath log updated
          → event: LearningPathLog progress = COMPLETE
            → UNLOCK rules may fire
```

### Determinazione dell'elemento corrente

Dopo ogni aggiornamento, il sistema determina su quale elemento l'utente dovrebbe lavorare successivamente:
1. Trova il primo elemento con `progress === "START"` (in corso).
2. Se non ce ne sono, trova il primo elemento con `progress === null` (non iniziato).
3. Se tutti gli elementi sono completi, `currentItemId` è null.

## Come funzionano insieme assegnazione e sblocco

I tipi di regola ASSIGN e UNLOCK si combinano per creare esperienze di apprendimento sequenziali:

### Passo 1: la regola ASSIGN crea le assegnazioni

Una regola ASSIGN con `initialVisibilityCondition` crea assegnazioni dove il primo percorso è UNLOCKED e i restanti sono LOCKED:

```json
{
  "ruleType": "ASSIGN",
  "learningPathsPool": ["intro_path", "intermediate_path", "advanced_path"],
  "initialVisibilityCondition": {
    "if": [{ "===": [{ "var": "index" }, 0] }, "UNLOCKED", "LOCKED"]
  },
  "assignmentMode": "LAZY"
}
```

Risultato:
- `intro_path` → UNLOCKED (l'utente può iniziare)
- `intermediate_path` → LOCKED (visibile ma non accessibile)
- `advanced_path` → LOCKED

### Passo 2: la regola UNLOCK monitora il completamento

Una regola UNLOCK monitora il completamento del percorso introduttivo:

```json
{
  "ruleType": "UNLOCK",
  "unlockLearningPathId": "intermediate_path",
  "assignmentMode": "EVENT",
  "eventMatchType": "INSTANCE",
  "eventMatchEntity": "LearningPathLog",
  "eventMatchEntityId": "intro_path",
  "eventMatchCondition": { "===": [{ "var": "progress" }, "COMPLETE"] }
}
```

### Passo 3: il completamento attiva lo sblocco

Quando l'utente completa `intro_path`:
1. Il progresso del LearningPathLog diventa `COMPLETE`.
2. L'evento corrisponde alla regola UNLOCK.
3. Il sistema trova l'assegnazione LOCKED esistente per `intermediate_path`.
4. L'assegnazione viene aggiornata: `visibility: "UNLOCKED"`, `unlockedAt` impostato, `unlockedByRuleId` impostato.
5. L'utente può ora accedere a `intermediate_path`.

Una seconda regola UNLOCK gestirebbe lo sblocco di `advanced_path` al completamento di `intermediate_path`.

## Deduplicazione

Le regole di assegnazione tracciano quali combinazioni (regola, periodo, utente) sono già state valutate, utilizzando un record **LearningPathRuleEvaluation**. Questo previene assegnazioni duplicate quando:
- Una regola LAZY viene valutata più volte per lo stesso utente.
- Una regola EVENT si attiva su più eventi nello stesso periodo.
- Una regola RECURRING si resetta — ogni nuovo periodo ha il proprio controllo di valutazione.

Il `periodId` segue lo stesso formato del dominio delle missioni: `"PERMANENT"` per le regole permanenti, `"YYYY-MM-DD"` per le ricorrenze giornaliere, `"YYYY-Www"` per quelle settimanali, ecc.

## Riepilogo dei concetti chiave

| Concetto | Scopo |
|----------|-------|
| **LearningPath** | Contenitore di contenuti di livello superiore con una sequenza ordinata di elementi polimorfici |
| **LearningGroup** | Contenitore annidato con tipi semantici: `story`, `test`, `custom` |
| **LearningPathRule** | Controlla l'assegnazione (`ASSIGN`) e l'accesso (`UNLOCK`) ai percorsi di apprendimento |
| **LearningPathAssignment** | Record per utente con `visibility` (LOCKED/UNLOCKED) e `state` (PENDING/ACTIVE/ENDED) |
| **LearningPathLog** | Record dei progressi per utente con tracciamento per elemento e storico versionato |
| **items** | Array polimorfico di riferimenti (`itemId`, `itemType`, `languages`) |
| **completionRule / outcomeRule / startRule** | Espressioni JsonLogic che calcolano i progressi aggregati dagli stati degli elementi figli |
| **initialVisibilityCondition** | JsonLogic che determina LOCKED o UNLOCKED al momento dell'assegnazione |
| **source** | Collegamento semantico tra learning group (es. relazione test → story) |
| **Propagazione dei progressi** | Il completamento di un elemento figlio si propaga automaticamente al gruppo e al percorso padre |

## Domini correlati

- **Dominio Reward e Currency**: il completamento di learning path, learning group e slide attiva le regole di ricompensa per l'erogazione di valuta virtuale.
- **Dominio Mission**: il completamento dei learning path può alimentare il progresso delle missioni tramite entity matching.
- **Dominio Streak**: il completamento di quiz e attività all'interno dei learning path può alimentare i contatori delle streak.
- **Cross-Cutting Patterns**: espressioni JsonLogic (completionRule, outcomeRule, startRule), entity matching, timeframe e pattern di assegnazione utilizzati in tutto questo dominio.
