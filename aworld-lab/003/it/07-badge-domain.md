Il sistema badge assegna riconoscimenti visivi agli utenti quando raggiungono traguardi specifici. Risponde a domande come _"Questo utente ha completato il percorso di onboarding e ha guadagnato il badge di benvenuto?"_ o _"Quante volte questo utente ha ricevuto il badge Top Performer?"_

> Questa sezione copre il modello badge completo: lifecycle della configurazione, collegamento alla sorgente di progresso, integrazione con le reward rule e il record badge lato utente. È rilevante per chiunque configuri badge tramite il dashboard o li integri via API. Per una panoramica di alto livello, consultare i Fondamenti di Gamification. Per l'integrazione con le reward rule (come vengono assegnati i badge), consultare il Dominio Reward e Currency.

Il dominio è costruito su due entità:

```
BadgeConfiguration  (il template: cos'è il badge e cosa ne guida l'assegnamento)
      │
      └──▶ Badge  (record per utente: istanze guadagnate con storico degli assegnamenti)
                │
                └──▶ BadgeLog  (record immutabile di ogni singolo assegnamento)
```

## Badge Configuration

Una **Badge Configuration** definisce _cos'è il badge_, _come appare_ e _quale traguardo dell'utente ne innesca l'assegnamento_. È il template che gli amministratori creano e pubblicano prima che i badge possano essere assegnati.

### Campi

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `badgeConfigurationId` | nanoid | Identificatore univoco |
| `name` | string | Nome di riferimento leggibile (es. "Completatore Learning Path") |
| `image` | URL | Immagine del badge — **obbligatoria** |
| `origin` | `CATALOG` \| `CUSTOM` | Se il badge proviene dal catalogo AWorld o è stato creato dal cliente |
| `catalogBadgeConfigurationId` | nanoid? | Riferimento alla sorgente del catalogo quando `origin` è `CATALOG` |
| `syncWithCatalog` | boolean? | Se true, il badge si aggiorna automaticamente quando cambia la sorgente nel catalogo |
| `progressSourceEntityType` | `MissionConfiguration` \| `LearningPath` | Il tipo di entità il cui completamento guida l'assegnamento del badge |
| `progressSourceEntityId` | nanoid | La Mission Configuration o il Learning Path specifico che innesca l'assegnamento |
| `defaultLang` | lang | Codice lingua predefinito per le traduzioni |
| `langs` | lang[] | Tutti i codici lingua supportati (1–10) |
| `accountId` | string | Account a cui appartiene il badge |
| `workspaceId` | string | Workspace a cui appartiene il badge |
| `createdAt` | ISO datetime | Timestamp di creazione |
| `updatedAt` | ISO datetime | Timestamp dell'ultimo aggiornamento |

### Traduzioni

Ogni Badge Configuration supporta la visualizzazione multilingua tramite un array `translations`. Ogni traduzione contiene:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `lang` | lang | Codice lingua (es. `en`, `it`, `ar`) |
| `label` | string | Nome del badge in questa lingua |
| `description` | string | Spiegazione di come guadagnare il badge |

### Tag

Le Badge Configuration supportano l'assegnazione di tag, permettendo categorizzazione e targeting:

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `tagId` | nanoid | Il tag assegnato a questa configurazione |
| `priority` | number | Ordine di visualizzazione quando sono assegnati più tag |

I tag sulle badge configuration permettono filtro e raggruppamento nel dashboard, nonché la limitazione delle reward rule a categorie specifiche di badge.

### Lifecycle

Le Badge Configuration seguono un lifecycle di pubblicazione/archiviazione:

```
    DRAFT ──▶ PUBLISHED ──▶ ARCHIVED
                  │
                  └──▶ DRAFT (unarchive)
```

- **DRAFT**: La configurazione esiste ma non è ancora attiva. I badge non possono essere assegnati in questo stato.
- **PUBLISHED**: La configurazione è attiva. Le reward rule che fanno riferimento a questo badge possono innescare gli assegnamenti.
- **ARCHIVED**: La configurazione è inattiva. Non si verificano nuovi assegnamenti. Può essere ripristinata a PUBLISHED tramite unarchive.

### Sorgente di Progresso

I campi `progressSourceEntityType` e `progressSourceEntityId` definiscono _cosa deve realizzare l'utente_ per guadagnare il badge:

- **`MissionConfiguration`**: il badge è collegato a un template di missione specifico. Quando la reward rule si attiva al completamento della missione, il badge viene assegnato.
- **`LearningPath`**: il badge è collegato a un learning path specifico. Il completamento del learning path innesca l'assegnamento tramite una reward rule.

Questo campo è informativo per il frontend — indica all'app quale entità visualizzare come sorgente di progresso del badge, abilitando barre di progresso e visualizzazione dello stato di completamento.

## Come Funziona l'Assegnamento dei Badge

I badge non vengono assegnati direttamente — vengono assegnati tramite il sistema delle **Reward Rule**. Il collegamento è:

```
RewardRule  (rewardType: BADGE, badgeConfigurationId: ...)
      │
      ├── matchEntity: Mission | LearningPath | Activity | ...
      ├── matchCondition: { isCompleted: true }  (solo al completamento)
      └──▶ BadgeConfiguration assegnata all'utente → record Badge creato
```

Il vincolo fondamentale: **i badge vengono assegnati solo quando l'entità che li innesca raggiunge il completamento**, non durante il progresso parziale. Una reward rule per l'assegnamento di badge deve includere un controllo `isCompleted` nel suo `matchCondition` per evitare attivazioni premature.

Consultare il [Dominio Reward e Currency](03-reward-and-currency-domain.md) per il modello completo delle reward rule, incluso il tipo di reward `BADGE`.

## Badge (Record Utente)

Un **Badge** è il record per utente che rappresenta un badge guadagnato. Aggrega tutte le istanze di un badge specifico assegnate allo stesso utente.

### Campi

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `badgeConfigurationId` | nanoid | Riferimento alla Badge Configuration |
| `userId` | nanoid | L'utente che ha guadagnato il badge |
| `count` | number | Numero totale di volte in cui il badge è stato assegnato a questo utente |
| `firstAssignedAt` | ISO datetime | Quando l'utente ha guadagnato il badge per la prima volta |
| `lastAssignedAt` | ISO datetime | Quando l'utente ha guadagnato il badge più di recente |
| `defaultLang` | lang | Lingua predefinita per la visualizzazione |
| `translation` | object | Label e descrizione localizzate per la lingua dell'utente che fa la richiesta |
| `badgeLogs` | BadgeLog[] | Storico completo degli assegnamenti individuali |
| `createdAt` | ISO datetime | Timestamp di creazione del record |
| `updatedAt` | ISO datetime | Timestamp dell'ultimo aggiornamento |

### Count e Ricorrenza

Il campo `count` riflette quante volte il badge è stato assegnato all'utente. I badge possono essere guadagnati più volte se la condizione che li innesca si ripete — ad esempio, completando la stessa missione ricorrente ogni mese. Ogni assegnamento crea una nuova voce BadgeLog.

Un `count` pari a 1 significa che il badge è stato guadagnato esattamente una volta. Un valore più alto indica un traguardo ricorrente.

## Badge Log

Un **BadgeLog** è un record immutabile di un singolo evento di assegnamento badge. Fornisce un audit trail completo di come e quando è stata guadagnata ogni istanza del badge.

### Campi

| Campo | Tipo | Descrizione |
|-------|------|-------------|
| `sourceEntityType` | string | Il tipo di entità che ha innescato l'assegnamento (es. `Mission`, `LearningPath`) |
| `sourceEntityId` | nanoid | L'istanza specifica dell'entità che ha innescato l'assegnamento |
| `rewardRuleId` | nanoid | La reward rule che ha elaborato l'assegnamento |
| `assignedAt` | ISO datetime | Quando si è verificato questo specifico assegnamento |

La combinazione di `sourceEntityType` e `sourceEntityId` identifica esattamente quale completamento di missione o learning path ha innescato il badge. Il `rewardRuleId` traccia quale regola ha valutato l'evento.

## Esempio: Badge Assegnato al Completamento di un Learning Path

### Step 1: Creare la Badge Configuration

```json
{
  "badgeConfigurationId": "bc-lp-onboarding",
  "name": "Completatore Onboarding",
  "image": "https://cdn.example.com/badges/onboarding.png",
  "origin": "CUSTOM",
  "progressSourceEntityType": "LearningPath",
  "progressSourceEntityId": "lp-onboarding-2025",
  "defaultLang": "it",
  "langs": ["en", "it"],
  "translations": [
    { "lang": "en", "label": "Onboarding Completer", "description": "Awarded for completing the onboarding learning path." },
    { "lang": "it", "label": "Completamento Onboarding", "description": "Assegnato al completamento del percorso di onboarding." }
  ]
}
```

### Step 2: Pubblicare la Badge Configuration

```
POST /badge-configurations/{badgeConfigurationId}/publish
```

### Step 3: Creare la Reward Rule

```json
{
  "ruleType": "INSTANCE",
  "matchEntity": "LearningPath",
  "matchEntityId": "lp-onboarding-2025",
  "matchCondition": { "===": [{ "var": "event.progress" }, "COMPLETE"] },
  "applicationMode": "ALWAYS",
  "rewards": [
    {
      "rewardType": "BADGE",
      "badgeConfigurationId": "bc-lp-onboarding"
    }
  ]
}
```

### Step 4: Cosa Succede a Runtime

1. Un utente completa il learning path di onboarding.
2. Un evento `LearningPathLog` viene pubblicato con `progress: COMPLETE`.
3. Il motore delle reward valuta il `matchCondition` della regola — supera il controllo.
4. Viene creato un assegnamento badge: il record Badge dell'utente per `bc-lp-onboarding` viene creato (o il `count` viene incrementato se l'aveva già guadagnato in precedenza).
5. Una voce BadgeLog viene scritta con `sourceEntityType: LearningPath`, `sourceEntityId: lp-onboarding-2025` e il `rewardRuleId`.

### Step 5: L'Utente Recupera i Propri Badge

```
GET /badges/bc-lp-onboarding
```

La risposta include `count: 1`, `firstAssignedAt` e l'array badgeLogs con il singolo evento di assegnamento.

## Riepilogo dei Concetti Chiave

| Concetto | Scopo |
|----------|-------|
| **BadgeConfiguration** | Template che definisce cos'è il badge, la sua immagine, le traduzioni e la sorgente di progresso |
| **progressSourceEntityType** | Collega il badge a una MissionConfiguration o Learning Path per la visualizzazione del progresso nel frontend |
| **Lifecycle** | DRAFT → PUBLISHED → ARCHIVED controlla quando un badge può essere assegnato |
| **Reward Rule (tipo BADGE)** | Il meccanismo che assegna effettivamente il badge — non serve expression né redemption mode |
| **Badge** | Record aggregato per utente: count, date del primo/ultimo assegnamento, storico completo |
| **BadgeLog** | Record immutabile di ogni assegnamento individuale con tracciabilità dell'entità sorgente e della regola |
| **count** | Quante volte il badge è stato guadagnato — supporta scenari di traguardo ricorrente |

## Domini Correlati

- **Dominio Reward e Currency**: la reward rule con `rewardType: BADGE` è il meccanismo che innesca l'assegnamento del badge. Comprendere la risoluzione ALWAYS/FALLBACK e le match condition è essenziale per la configurazione dei badge.
- **Dominio Mission**: il completamento della missione è un trigger primario per l'assegnamento dei badge. Il `progressSourceEntityType: MissionConfiguration` collega un badge a un template di missione specifico.
- **Dominio Learning Content**: il completamento del learning path è l'altro trigger primario. Il `progressSourceEntityType: LearningPath` collega un badge a un learning path specifico.
- **Pattern Trasversali**: il pattern CATALOG/CUSTOM di origine, il matching delle entità (INSTANCE/ENTITY/TAG) e le match condition JsonLogic sono condivisi con gli altri domini.
