Il sistema di reward distribuisce automaticamente valuta virtuale quando gli utenti eseguono azioni. Risponde a domande come _"Quanti punti dovrebbe ricevere questo utente per aver completato un quiz difficile?"_ e _"L'utente ha abbastanza crediti per riscattare questa ricompensa?"_

Questa sezione copre il modello completo dei reward: valutazione delle regole con risoluzione per priorità (ALWAYS/FALLBACK), gestione delle valute, ciclo di vita delle transazioni e tracciamento dei saldi. È rilevante per chiunque configuri le regole di reward o integri l'economia virtuale via API. Per una panoramica di alto livello, vedi i Fondamenti della Gamification. Per i pattern condivisi (espressioni JsonLogic, entity matching), vedi i Pattern Trasversali.

Il dominio collega la valutazione delle regole a un'economia virtuale:

```
RewardRule  (quando e quanto assegnare)
      │
      └──▶ VirtualTransaction  (una voce di registro: credito o debito)
                │
                └──▶ VirtualBalance  (il saldo corrente dell'utente per valuta)
```

L'economia virtuale è alimentata da:

```
VirtualCurrency  (definisce una valuta: XP, crediti, token, ecc.)
```

## Reward Rule

Una **Reward Rule** definisce quando la valuta virtuale deve essere assegnata e in quale quantità. Ogni regola osserva eventi specifici (completamento di attività, quiz superato, missione completata, ecc.) e genera transazioni quando le condizioni sono soddisfatte.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `rewardRuleId` | string | Identificatore univoco |
| `name` | string | Nome leggibile |
| `ruleType` | `INSTANCE` \| `ENTITY` \| `TAG` | Modalità di corrispondenza degli eventi |
| `matchEntity` | enum | Quale tipo di entità attiva questa regola (vedi sotto) |
| `matchEntityId` | string? | ID specifico dell'entità o del tag (obbligatorio per INSTANCE e TAG) |
| `matchCondition` | JsonLogic | Filtraggio aggiuntivo degli eventi |
| `applicationMode` | `ALWAYS` \| `FALLBACK` \| `DISABLED` | Quando questa regola si attiva |
| `rewards` | Reward[] | 1–10 erogazioni di ricompensa |
| `origin` | `CATALOG` \| `CUSTOM` | Origine della creazione |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (1–10) |

### Match Entities

Le reward rule supportano il set più ampio di match entities della piattaforma:

| Match Entity | Triggers On |
|-------------|-------------|
| `Mission` | Completamento di una missione |
| `Activity` | Completamento di un'attività |
| `Quiz` | Completamento di un quiz |
| `Tag` | Qualsiasi entità con un tag corrispondente |
| `LearningPath` | Progresso/completamento di un percorso di apprendimento |
| `LearningGroup` | Progresso/completamento di un gruppo di apprendimento |
| `Slide` | Completamento di una slide |

Il tipo di corrispondenza funziona come negli altri domini:
- **`INSTANCE`**: corrisponde a un'entità specifica tramite ID.
- **`ENTITY`**: corrisponde a qualsiasi entità del tipo indicato.
- **`TAG`**: corrisponde a qualsiasi entità con il tag indicato.

### Modalità di applicazione e ordine di risoluzione

Le modalità di applicazione controllano la priorità della valutazione delle regole:

**`ALWAYS`** — Regole primarie. Vengono valutate per prime e si attivano ogni volta che le loro condizioni sono soddisfatte.

**`FALLBACK`** — Regole di riserva. Si attivano _solo se nessuna regola ALWAYS ha trovato corrispondenza_ per lo stesso evento. Questo impedisce l'accumulo di ricompense garantendo al contempo che esista sempre una ricompensa di base.

**`DISABLED`** — Regole inattive. Non vengono valutate.

L'algoritmo di risoluzione:

1. Si verifica un evento (ad es. quiz completato).
2. Il sistema interroga tutte le regole `ALWAYS` che corrispondono al tipo e all'ID dell'entità dell'evento (attraverso i tipi di regola INSTANCE, ENTITY e TAG).
3. Per ogni regola, la `matchCondition` viene valutata rispetto ai dati dell'evento.
4. Se una o più regole ALWAYS corrispondono → si usano quelle regole. Fine.
5. Se nessuna regola ALWAYS corrisponde → si interrogano le regole `FALLBACK`, si valutano le condizioni, si usano quelle.
6. Mai entrambe — o si attivano le regole ALWAYS o si attivano le regole FALLBACK, non entrambe.

Questo design abilita pattern come:
- Regola ALWAYS: "Assegna 20 XP per qualsiasi quiz HARD" (specifica).
- Regola FALLBACK: "Assegna 5 XP per qualsiasi quiz" (base, solo quando non si applica nessuna regola specifica).

### Match Condition

La `matchCondition` riceve `{ event, previousEvent }` come contesto, dove `previousEvent` è lo stato dell'entità prima dell'aggiornamento corrente. Questo consente condizioni basate sulle transizioni di stato:

```json
// Only reward when progress changes to COMPLETE
{
  "and": [
    { "===": [{ "var": "event.progress" }, "COMPLETE"] },
    { "!==": [{ "var": "previousEvent.progress" }, "COMPLETE"] }
  ]
}
```

```json
// Only reward successful quizzes
{ "===": [{ "var": "event.outcome" }, "SUCCESS"] }
```

### Array rewards

Ogni regola contiene da 1 a 10 definizioni di ricompensa. Una singola regola può assegnare più valute contemporaneamente:

| Field | Type | Description |
|-------|------|-------------|
| `virtualCurrencyId` | nanoid | Quale valuta assegnare |
| `redemptionMode` | `AUTO` \| `MANUAL` | Come viene finalizzata la transazione |
| `expression` | JsonLogic | Valuta l'importo da assegnare |

**Modalità di riscatto**:
- **`AUTO`**: La transazione viene completata immediatamente — il saldo dell'utente viene accreditato istantaneamente. Tipico per XP e ricompense automatiche.
- **`MANUAL`**: La transazione viene creata come PENDING e richiede un'azione esplicita per il riscatto. Utile per flussi di riscatto di premi in cui l'utente deve reclamare la ricompensa.

**Esempi di expression**:

```json
// Static: always award 100 points
100

// Dynamic: award based on quiz difficulty
{
  "if": [
    { "===": [{ "var": "event.difficulty" }, "HARD"] }, 20,
    { "===": [{ "var": "event.difficulty" }, "MEDIUM"] }, 10,
    5
  ]
}
```

L'expression riceve `{ event }` come contesto. Se valuta `0` o un valore non numerico, la transazione viene silenziosamente saltata.

### Event Remapping

Gli eventi sorgente vengono rimappati ai tipi di entità padre prima della corrispondenza con le regole:

| Source Event | Maps To |
|-------------|---------|
| `ActivityLog` | `Activity` |
| `LearningPathLog` | `LearningPath` |
| `LearningGroupLog` | `LearningGroup` |
| `SlideLog` | `Slide` |

Questo significa che le regole sono definite rispetto all'entità padre (ad es. `matchEntity: "Activity"`), non rispetto all'entità log.

## Virtual Currency

Una **Virtual Currency** definisce un tipo di punto, credito o token all'interno di un workspace. Ogni workspace può avere più valute che servono scopi diversi.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `virtualCurrencyId` | nanoid | Identificatore univoco |
| `name` | string | Nome visualizzato |
| `icon` | URL? | Icona opzionale per la UI |
| `minAllowedBalance` | number? | Soglia minima opzionale per i saldi degli utenti |
| `maxAllowedBalance` | number? | Soglia massima opzionale per i saldi degli utenti |
| `origin` | `CATALOG` \| `CUSTOM` | Origine della creazione |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (1–10) |

### Configurazioni tipiche

| Currency | Purpose | Balance Constraints |
|----------|---------|-------------------|
| Experience Points (XP) | Determina le classifiche e i livelli | Nessun limite (min: 0) |
| Credits | Guadagnati e spesi per le ricompense | Min: 0, max opzionale |
| Streak Tokens | Spesi per congelare le streak | Min: 0 |

Una configurazione comune utilizza due valute: **XP** per la progressione (non può essere speso) e **credits** per le ricompense (guadagnati e riscattabili). I client possono definire qualsiasi numero di valute.

## Virtual Transaction

Una **Virtual Transaction** è una voce di registro che registra un credito o un debito sul saldo in valuta virtuale di un utente.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `virtualTransactionId` | nanoid | Identificatore univoco |
| `virtualTransactionGroupId` | nanoid | Raggruppa transazioni correlate |
| `redemptionGroupId` | nanoid? | Raggruppa i riscatti |
| `userId` | nanoid | L'utente il cui saldo viene modificato |
| `virtualCurrencyId` | nanoid | Quale valuta |
| `direction` | `CREDIT` \| `DEBIT` | Aggiunta o rimozione |
| `amount` | number | L'importo (non deve essere zero) |
| `state` | `PENDING` \| `COMPLETED` \| `EXPIRED` \| `REJECTED` | Stato del ciclo di vita |
| `redemptionMode` | `AUTO` \| `MANUAL` | Come funziona la finalizzazione |
| `initiatorType` | enum | Cosa ha causato questa transazione (vedi sotto) |
| `initiator` | string | Identificatore dell'iniziatore (ad es. `"rewardRuleId#rr-123"`) |
| `counterpartType` | `USER` \| `SYSTEM` | L'altra parte |
| `counterpart` | string | Identificatore della controparte |
| `expiresAt` | ISO datetime? | Data di scadenza opzionale |
| `redeemedAt` | string? | Quando la transazione è stata riscattata |
| `additionalData` | record? | Metadati personalizzati |

### Tipi di initiator

| Initiator Type | Description |
|---------------|-------------|
| `USER` | Azione diretta dell'utente (ad es. spesa di crediti) |
| `REWARD_RULE` | Erogazione automatica dalla valutazione di una reward rule |
| `STREAK_RULE` | Deduzione per il congelamento della streak |
| `SYSTEM` | Processo automatizzato del sistema |
| `ADMIN` | Azione manuale dell'amministratore |

### Ciclo di vita della transazione

```
    transaction created
           │
    ┌──────▼──────┐
    │   PENDING    │ ◀── created but not finalized
    └──┬───┬───┬──┘
       │   │   │
       │   │   └── expiresAt reached
       │   │              │
       │   │       ┌──────▼──────┐
       │   │       │   EXPIRED   │  ◀── time ran out
       │   │       └─────────────┘
       │   │
       │   └──── explicitly denied
       │                │
       │         ┌──────▼──────┐
       │         │  REJECTED   │  ◀── insufficient balance, etc.
       │         └─────────────┘
       │
       └────── redeemed (AUTO or MANUAL)
                      │
               ┌──────▼──────┐
               │  COMPLETED  │  ◀── balance updated
               └─────────────┘
```

- **PENDING**: La transazione esiste ma non è stata ancora applicata al saldo.
- **COMPLETED**: La transazione è finalizzata e riflessa nel saldo.
- **EXPIRED**: La transazione non è stata riscattata prima di `expiresAt`. Stato terminale.
- **REJECTED**: La transazione è stata rifiutata (ad es. saldo insufficiente per un debito). Stato terminale.

Per la modalità di riscatto `AUTO`, la transazione passa direttamente a COMPLETED al momento della creazione. Per `MANUAL`, rimane PENDING fino a quando l'utente o l'amministratore non la riscatta esplicitamente.

## Virtual Balance

Un **Virtual Balance** tiene traccia del saldo corrente di un utente per una specifica valuta.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `userId` | nanoid | L'utente |
| `virtualCurrencyId` | nanoid | La valuta |
| `amount` | number | Saldo totale (incluse le transazioni in sospeso) |
| `availableAmount` | number | Saldo disponibile per la spesa (solo transazioni completate) |

### Amount vs. Available Amount

- **`amount`**: Il totale, incluse le transazioni PENDING. Rappresenta ciò che l'utente _avrà_ se tutte le transazioni in sospeso vengono completate.
- **`availableAmount`**: Solo le transazioni COMPLETED. Rappresenta ciò che l'utente _può spendere adesso_.

Per la modalità di riscatto `AUTO`, `amount` e `availableAmount` sono sempre uguali (poiché le transazioni vengono completate immediatamente). La differenza è rilevante solo per la modalità `MANUAL`, dove una ricompensa potrebbe essere in attesa di riscatto da parte dell'utente.

## Come vengono elaborati i reward

Quando un utente esegue un'azione che potrebbe attivare delle ricompense:

1. **Arrivo dell'evento**: Il sistema sorgente (Activity, Quiz, LearningPath, ecc.) pubblica un evento.
2. **Rimappatura dell'entità**: `ActivityLog` → `Activity`, `LearningPathLog` → `LearningPath`, ecc.
3. **Ricerca delle regole**: Il sistema interroga le regole corrispondenti attraverso tutti e tre i tipi di regola (INSTANCE, ENTITY, TAG) in parallelo.
4. **Risoluzione ALWAYS/FALLBACK**: Se una o più regole ALWAYS corrispondono, si usano quelle. Altrimenti, si usano le regole FALLBACK.
5. **Valutazione delle condizioni**: La `matchCondition` di ogni regola viene valutata rispetto a `{ event, previousEvent }`.
6. **Calcolo della transazione**: Per ogni regola corrispondente, per ogni reward nella regola:
   - L'`expression` del reward viene valutata rispetto a `{ event }`.
   - Se il risultato è un numero diverso da zero, viene preparato un input di transazione.
   - Se il risultato è zero o non numerico, il reward viene saltato.
7. **Creazione della transazione**: Le transazioni virtuali vengono create nel database.
8. **Aggiornamento del saldo**: Per le transazioni AUTO, il saldo dell'utente viene aggiornato immediatamente.

### Esempio: Reward Rule multi-valuta

Una singola regola che assegna sia XP che crediti per il completamento di un percorso di apprendimento:

```json
{
  "rewardRuleId": "rr-lp-complete",
  "ruleType": "ENTITY",
  "matchEntity": "LearningPath",
  "matchCondition": { "===": [{ "var": "event.progress" }, "COMPLETE"] },
  "applicationMode": "ALWAYS",
  "rewards": [
    {
      "virtualCurrencyId": "vc-xp",
      "redemptionMode": "AUTO",
      "expression": 50
    },
    {
      "virtualCurrencyId": "vc-credits",
      "redemptionMode": "AUTO",
      "expression": 100
    }
  ]
}
```

Quando un qualsiasi percorso di apprendimento viene completato: 50 XP + 100 crediti vengono accreditati istantaneamente.

### Esempio: ricompense dinamiche basate sulla difficoltà

```json
{
  "rewardRuleId": "rr-quiz-difficulty",
  "ruleType": "ENTITY",
  "matchEntity": "Quiz",
  "matchCondition": { "===": [{ "var": "event.outcome" }, "SUCCESS"] },
  "applicationMode": "ALWAYS",
  "rewards": [
    {
      "virtualCurrencyId": "vc-xp",
      "redemptionMode": "AUTO",
      "expression": {
        "if": [
          { "===": [{ "var": "event.difficulty" }, "HARD"] }, 20,
          { "===": [{ "var": "event.difficulty" }, "MEDIUM"] }, 10,
          5
        ]
      }
    }
  ]
}
```

### Esempio: FALLBACK di base

```json
// ALWAYS rule: 20 XP for any activity tagged "premium"
{
  "ruleType": "TAG",
  "matchEntity": "Tag",
  "matchEntityId": "premium",
  "matchCondition": { "===": [{ "var": "event.progress" }, "COMPLETE"] },
  "applicationMode": "ALWAYS",
  "rewards": [{ "virtualCurrencyId": "vc-xp", "redemptionMode": "AUTO", "expression": 20 }]
}

// FALLBACK rule: 5 XP for any activity (baseline)
{
  "ruleType": "ENTITY",
  "matchEntity": "Activity",
  "matchCondition": { "===": [{ "var": "event.progress" }, "COMPLETE"] },
  "applicationMode": "FALLBACK",
  "rewards": [{ "virtualCurrencyId": "vc-xp", "redemptionMode": "AUTO", "expression": 5 }]
}
```

Se un'attività con tag premium viene completata → 20 XP (la regola ALWAYS si attiva, la FALLBACK viene saltata).
Se un'attività senza tag viene completata → 5 XP (nessuna regola ALWAYS corrisponde, la FALLBACK si attiva).

## Riepilogo dei concetti chiave

| Concept | Purpose |
|---------|---------|
| **RewardRule** | Definisce quando e quanta valuta assegnare (7 match entities, risoluzione ALWAYS/FALLBACK) |
| **VirtualCurrency** | Definisce un tipo di valuta con vincoli di saldo opzionali |
| **VirtualTransaction** | Voce di registro: CREDIT o DEBIT, con ciclo di vita (PENDING→COMPLETED/EXPIRED/REJECTED) |
| **VirtualBalance** | Saldo corrente dell'utente per valuta (totale vs. disponibile) |
| **applicationMode** | `ALWAYS` (primaria) vs `FALLBACK` (riserva se nessuna ALWAYS corrisponde) vs `DISABLED` |
| **rewards array** | 1–10 erogazioni per regola, ciascuna con valuta, modalità ed expression |
| **redemptionMode** | `AUTO` (istantaneo) vs `MANUAL` (richiede riscatto esplicito) |
| **initiatorType** | Cosa ha causato la transazione: `USER`, `REWARD_RULE`, `STREAK_RULE`, `SYSTEM`, `ADMIN` |
| **Event remapping** | Le entità log (ActivityLog, ecc.) vengono mappate alle entità padre per la corrispondenza con le regole |
| **previousEvent** | Abilita condizioni basate sulle transizioni ("ricompensa solo quando il progresso cambia a COMPLETE") |

## Domini correlati

- **Dominio Mission**: il completamento delle missioni è uno degli eventi chiave che attiva le regole di ricompensa.
- **Dominio Learning Content**: il completamento di learning path e learning group attiva l'erogazione di ricompense.
- **Dominio Streak**: il meccanismo di freeze detrae valuta virtuale per preservare le streak.
- **Dominio Leaderboard**: le classifiche classificano gli utenti in base all'accumulo di valuta virtuale (es. XP).
- **Cross-Cutting Patterns**: espressioni JsonLogic, entity matching e pattern di remapping degli eventi utilizzati in tutto questo dominio.
