I servizi di dominio di AWorld Lab condividono un insieme di pattern architetturali che ricorrono tra missioni, streak, percorsi di apprendimento, ricompense e classifiche. Questo documento descrive ciascun pattern una sola volta, in modo che gli approfondimenti specifici per dominio possano farvi riferimento anziché ripeterlo.

## Sistema di espressioni JsonLogic

Diversi campi nella piattaforma accettano **espressioni JsonLogic** — regole codificate in JSON che vengono valutate a runtime rispetto a un oggetto di contesto. Questo consente ai client di definire condizioni complesse, calcoli e filtri esclusivamente tramite configurazione.

### Come funziona

Un'espressione JsonLogic è un oggetto JSON in cui le chiavi sono operatori e i valori sono argomenti. La piattaforma valuta l'espressione rispetto a un oggetto di contesto che contiene i dati rilevanti per quel punto di valutazione.

```json
// "Il progress dell'evento è uguale a COMPLETE?"
{ "===": [{ "var": "event.progress" }, "COMPLETE"] }

// "Assegna 20 punti per quiz HARD, 10 per MEDIUM, 5 per EASY"
{
  "if": [
    { "===": [{ "var": "event.difficulty" }, "HARD"] }, 20,
    { "===": [{ "var": "event.difficulty" }, "MEDIUM"] }, 10,
    5
  ]
}

// Condizione composta
{
  "and": [
    { "===": [{ "var": "event.progress" }, "COMPLETE"] },
    { "===": [{ "var": "event.outcome" }, "SUCCESS"] }
  ]
}
```

La piattaforma estende la libreria standard JsonLogic con operazioni `Math` (`sqrt`, `pow`, `min`, `max`, ecc.) e accesso a `Date`.

### Dove viene utilizzato

| Dominio | Campo Espressione | Oggetto di Contesto | Scopo |
|---------|-------------------|---------------------|-------|
| **MissionConfiguration** | `matchCondition` | `{ mission }` | Filtrare quali eventi contano ai fini del progresso |
| **MissionConfiguration** | `incrementExpression` | `{ user, event }` | Calcolare quanto progresso aggiunge ciascun evento |
| **MissionConfiguration** | `targetAmountExpression` | `{ user, mission }` | Calcolare l'obiettivo di completamento |
| **MissionRule** | `usersMatchCondition` | `{ user }` | Determinare quali utenti sono idonei |
| **MissionRule** | `missionsMatchCondition` | `{ mission }` | Filtrare quali configurazioni istanziare |
| **MissionRule** | `eventMatchCondition` | event data | Filtrare quali eventi attivano l'assegnazione (modalità EVENT) |
| **StreakConfiguration** | `matchCondition` | `{ event }` | Determinare se un evento conta ai fini di una streak |
| **StreakRule** | `usersMatchCondition` | `{ user }` | Determinare a quali utenti si applica questa regola |
| **StreakRule** | `freezeCostExpression` | `{ user, streak }` | Calcolare il costo in valuta virtuale per il congelamento |
| **LearningPathRule** | `usersMatchCondition` | `{ user, activeAssignments }` | Determinare l'idoneità dell'utente |
| **LearningPathRule** | `learningPathsMatchCondition` | `{ user, learningPath }` | Filtrare quali percorsi assegnare |
| **LearningPathRule** | `initialVisibilityCondition` | `{ learningPath, index, user }` | Determinare LOCKED o UNLOCKED per percorso |
| **LearningPathRule** | `eventMatchCondition` | event data | Filtrare quali eventi attivano UNLOCK |
| **RewardRule** | `matchCondition` | `{ event, previousEvent }` | Determinare se un evento qualifica per una ricompensa |
| **RewardRule** | `expression` della ricompensa | `{ event }` | Calcolare l'importo della ricompensa |

### Comportamenti importanti

- Un valore statico (es. `true`, `100`) è un'espressione valida — restituisce sempre quel valore.
- I campi mancanti nel contesto restituiscono `null`. Le espressioni dovrebbero gestire questa situazione in modo appropriato.
- I risultati numerici vengono forzati a numeri; i valori negativi nelle espressioni di costo vengono automaticamente invertiti per garantire un costo positivo.
- Le espressioni vengono memorizzate come JSON opaco — la piattaforma valida la sintassi JSON ma non valida la semantica delle espressioni al momento della scrittura.

---

## Pattern Configuration → Rule → Instance

Tre domini principali seguono una gerarchia a tre livelli in cui una **Configuration** definisce _cosa_ tracciare, una **Rule** definisce _quando e per chi_, e un'**Instance** traccia lo _stato per utente_:

```
Configuration  (cosa conta)
      │
      └──▶ Rule  (le regole del gioco: chi, quando, come)
              │
              └──▶ Instance  (record di tracciamento per utente o per gruppo)
```

| Livello | Dominio Mission | Dominio Streak | Dominio Learning Path |
|---------|----------------|----------------|----------------------|
| Configuration | MissionConfiguration | StreakConfiguration | _(incorporato in LearningPath)_ |
| Rule | MissionRule | StreakRule | LearningPathRule |
| Instance | Mission | Streak | LearningPathAssignment |
| Log | MissionLog | StreakLog | LearningPathLog |

Ogni livello ha il proprio ciclo di vita, e le modifiche a livello di Configuration o Rule non alterano retroattivamente le Instance esistenti — influenzano solo le assegnazioni future.

---

## Pattern di Entity Matching

Diversi servizi utilizzano un **sistema di matching a tre modalità** coerente per determinare quali entità sono rilevanti per una regola o configurazione:

### Tipi di match

| Tipo di Match | Comportamento | `matchEntityId` Obbligatorio |
|---------------|---------------|-------------------------------|
| `INSTANCE` | Corrisponde a un'entità _specifica_ tramite ID. Esempio: completare l'attività `abc123`. | Sì |
| `ENTITY` | Corrisponde a _qualsiasi_ entità del tipo indicato. Esempio: completare qualsiasi quiz. | No |
| `TAG` | Corrisponde a qualsiasi entità associata al tag indicato. Esempio: qualsiasi attività con tag `christmas`. | Sì (l'ID del tag) |

### Entità di match per dominio

| Dominio | Entità di Match Disponibili |
|---------|----------------------------|
| MissionConfiguration | `Activity`, `Quiz`, `Tag` |
| StreakConfiguration | `Mission`, `Activity`, `Quiz`, `Tag` |
| RewardRule | `Mission`, `Activity`, `Quiz`, `Tag`, `LearningPath`, `LearningGroup`, `Slide` |

> **Vincolo**: Quando `matchType` è `INSTANCE` o `TAG`, il campo `matchEntityId` è obbligatorio. Quando `matchType` è `ENTITY`, `matchEntityId` deve essere assente.

Il tipo di match `TAG` è particolarmente potente — combinandolo con un'espressione JsonLogic `matchCondition`, è possibile creare regole altamente mirate come _"solo attività con tag `christmas` completate a dicembre"_.

---

## Timeframe e scheduling

Le regole e le istanze runtime condividono un modello di timeframe comune che controlla quando sono attive.

### Tipi di timeframe

| Tipo | Comportamento | `timeframeEndsAt` |
|------|---------------|-------------------|
| `PERMANENT` | Inizia a `timeframeStartsAt`, prosegue indefinitamente | Non obbligatorio |
| `RANGE` | Attivo tra `timeframeStartsAt` e `timeframeEndsAt`, una sola volta | Obbligatorio |
| `RECURRING` | Si ripete con una cadenza definita tra le date di inizio e fine | Obbligatorio |

### Ricorrenza

Quando `timeframeType` è `RECURRING`, il campo `recurrence` definisce la cadenza di reset:

| Ricorrenza | Comportamento |
|-----------|---------------|
| `DAILY` | Reset ogni giorno |
| `WEEKLY` | Reset ogni settimana |
| `MONTHLY` | Reset ogni mese |
| `CUSTOM` | Reset secondo un'espressione cron (`scheduleCron`) |

> **Vincolo**: `scheduleCron` è obbligatorio solo quando `recurrence` è `CUSTOM`. L'espressione cron utilizza il formato standard IANA.

### Gestione del fuso orario

| Tipo di Timezone | Comportamento | `timeframeTimezone` |
|-----------------|---------------|---------------------|
| `FIXED` | Tutti gli utenti sperimentano le transizioni nello stesso momento assoluto | Obbligatorio (fuso orario IANA, es. `"Europe/Rome"`) |
| `USER` | Le transizioni di ciascun utente sono relative al proprio fuso orario locale | Non obbligatorio |

Il timezone `USER` è ideale per regole giornaliere/settimanali in cui l'equità richiede che ogni utente abbia gli stessi confini orari locali. Il timezone `FIXED` è appropriato per eventi globali che devono iniziare e terminare simultaneamente per tutti.

### Servizi che utilizzano questo pattern

MissionRule, StreakRule, LearningPathRule, RuntimeLeaderboard — tutti utilizzano gli stessi nomi di campo e lo stesso insieme di valori validi.

---

## Ciclo di vita degli stati

Le entità con un timeframe seguono un ciclo di vita coerente a tre stati:

```
              il tempo passa
                 │
    ┌────────────▼────────────┐
    │         PENDING         │  ◀── prima di timeframeStartsAt
    └────────────┬────────────┘
                 │ timeframeStartsAt raggiunto
                 ▼
    ┌────────────────────────┐
    │         ACTIVE          │  ◀── tra inizio e fine
    └────────────┬────────────┘
                 │ timeframeEndsAt raggiunto (non per PERMANENT)
                 ▼
    ┌────────────────────────┐
    │          ENDED          │  ◀── dopo timeframeEndsAt
    └─────────────────────────┘
```

- **PENDING**: L'entità esiste ma non è ancora operativa. È stata creata in anticipo rispetto alla sua data di inizio.
- **ACTIVE**: L'entità è operativa e accetta interazioni.
- **ENDED**: Il timeframe dell'entità è trascorso. Stato terminale.

> **Nota**: Le entità `PERMANENT` non raggiungono mai lo stato `ENDED` — rimangono `ACTIVE` indefinitamente una volta avviate.

Le transizioni di stato sono gestite da processi schedulati che valutano periodicamente il timeframe di ciascuna entità e aggiornano lo stato di conseguenza. Il calcolo è deterministico: dato il momento attuale e i campi del timeframe, lo stato può sempre essere derivato.

---

## Multi-lingua e localizzazione

Tutte le entità che contengono contenuti supportano più lingue attraverso un pattern coerente.

### Campi lingua sull'entità principale

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `defaultLang` | language code | La lingua principale per questa entità |
| `langs` | language code[] | Tutte le lingue supportate (da 1 a 10) |

### Entità di traduzione

I contenuti traducibili vengono memorizzati in entità **Translation** separate anziché incorporati nell'entità principale. Ogni traduzione è indicizzata dall'ID dell'entità padre più un campo `lang`.

```
LearningPath (defaultLang: "en", langs: ["en", "it", "fr"])
      │
      ├── LearningPathTranslation (lang: "en", title: "Onboarding", description: "...")
      ├── LearningPathTranslation (lang: "it", title: "Onboarding", description: "...")
      └── LearningPathTranslation (lang: "fr", title: "Intégration", description: "...")
```

I campi traducibili tipici includono `title`, `description` e `image` (per immagini specifiche per lingua). Ogni dominio definisce il proprio insieme di campi traducibili.

### Storico delle traduzioni

Le entità di configurazione che supportano audit trail mantengono anche record di **TranslationHistory**, fornendo un versionamento completo dei contenuti tradotti.

### Servizi che utilizzano questo pattern

MissionConfiguration, MissionRule, StreakConfiguration, StreakRule, RewardRule, LearningPath, LearningGroup, Quiz, Slide, Activity, VirtualCurrency, RuntimeLeaderboardConfiguration.

---

## Origin e sincronizzazione con il catalogo

Le entità di contenuto e configurazione tracciano la propria **origin** — se sono state create da un template di catalogo, generate dall'IA, o definite in modo personalizzato dal client.

### Valori di origin

| Origin | Descrizione |
|--------|-------------|
| `CATALOG` | Creato da un template pre-costruito nel workspace del catalogo |
| `CUSTOM` | Creato da zero dal client |
| `AI` | Generato dalla creazione di contenuti tramite IA (solo Learning Path e Learning Group) |

### Campi di riferimento al catalogo

Quando `origin` è `CATALOG`, l'entità memorizza un riferimento alla propria sorgente nel catalogo:

| Pattern del Campo | Esempio |
|-------------------|---------|
| `catalog<Entity>Id` | `catalogMissionRuleId`, `learningPathCatalogId`, `catalogRewardRuleId` |
| `syncWithCatalog` | Booleano — indica se mantenere l'entità sincronizzata con i futuri aggiornamenti del catalogo |

> **Vincolo**: Quando `origin` è `CATALOG`, l'ID di riferimento al catalogo deve essere impostato. Quando `origin` è `CUSTOM`, deve essere assente.

### Servizi che utilizzano questo pattern

MissionConfiguration, MissionRule, StreakConfiguration, StreakRule, RewardRule, LearningPath, LearningGroup, Quiz, Slide, Activity, VirtualCurrency.

---

## Sistema di tag

I tag sono un meccanismo trasversale fondamentale utilizzato per la categorizzazione, il targeting e la segmentazione nell'intera piattaforma.

### Struttura dei tag

Ogni tag è definito da un **namespace** e una **variant**:

- **Namespace**: la categoria (es. `department`, `region`, `tier`)
- **Variant**: il valore specifico (es. `marketing`, `europe`, `gold`)

### Assegnazione dei tag

I tag possono essere assegnati virtualmente a qualsiasi entità — utenti, attività, quiz, percorsi di apprendimento, gruppi di apprendimento, slide, configurazioni di missione, regole di missione, configurazioni di streak e regole di streak. Ogni assegnazione include un valore di **priority** per l'ordinamento.

### Tag nel motore delle regole

I tag svolgono tre ruoli critici nei sistemi di regole della piattaforma:

1. **Entity matching**: Le regole con `matchType: TAG` puntano a tutte le entità associate a un tag specifico, abilitando raggruppamenti tematici (es. tutte le attività con tag `christmas`).
2. **Segmentazione utenti**: Le espressioni `usersMatchCondition` possono fare riferimento ai tag degli utenti per targettizzare gruppi specifici di utenti.
3. **Targeting per gruppo**: Le missioni di gruppo e le classifiche della community sono delimitate per tag, abilitando esperienze basate su team e segmenti.

---

## Riepilogo

| Pattern | Scopo | Utilizzato Da |
|---------|-------|---------------|
| **JsonLogic** | Condizioni e calcoli dichiarativi | Tutte le entità di regole e configurazione |
| **Config → Rule → Instance** | Modellazione gerarchica del dominio | Mission, Streak, LearningPath |
| **Entity Matching** | Targeting flessibile degli eventi (INSTANCE/ENTITY/TAG) | MissionConfig, StreakConfig, RewardRule |
| **Timeframe & Scheduling** | Confini temporali e ricorrenza | MissionRule, StreakRule, LPRule, Leaderboard |
| **State Lifecycle** | PENDING → ACTIVE → ENDED | Tutte le entità di regole e istanze |
| **Multi-Lingua** | Contenuti localizzati tramite entità Translation | Tutte le entità con contenuti |
| **Origin & Catalog** | Sourcing da template e sincronizzazione | Tutte le entità di configurazione |
| **Sistema di Tag** | Categorizzazione, targeting, segmentazione | Trasversale a tutti i domini |
