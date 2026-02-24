Il sistema di leaderboard trasforma l'accumulo di valuta virtuale in classifiche competitive. Risponde a domande come _"Chi sono i primi 10 utenti nel reparto marketing questa settimana?"_ e _"Qual è la mia posizione attuale?"_

> Questa sezione copre il modello completo delle leaderboard: template di configurazione, calcolo dei ranking basato su query, catene di istanze ricorrenti e gestione dei fusi orari. È rilevante per chiunque configuri meccaniche competitive o integri le leaderboard via API. Per una panoramica di alto livello, vedi i Fondamenti della Gamification. Per i pattern condivisi (timeframe, ciclo di vita dello stato), vedi i Pattern Trasversali.

Il dominio si basa su un'architettura a due livelli che separa _cosa_ viene classificato da _quando_ viene classificato:

```
RuntimeLeaderboardConfiguration  (il template: cosa calcolare)
      │
      └──▶ RuntimeLeaderboard  (l'istanza: un periodo specifico e il suo stato)
```

Una singola configurazione può alimentare molteplici istanze runtime. Ad esempio, una configurazione "Top Punti Questa Settimana" genera automaticamente una nuova istanza settimanale ogni lunedì, ciascuna con classifiche indipendenti.

## Runtime Leaderboard Configuration

Una **Configuration** definisce _cosa_ calcola la leaderboard: quali utenti sono idonei, come vengono calcolati i punteggi e come vengono visualizzati i risultati.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `runtimeLeaderboardConfigurationId` | nanoid | Identificatore univoco |
| `name` | string | Nome leggibile |
| `description` | string? | Descrizione opzionale |
| `query` | QuerySpec | La definizione completa del calcolo della classifica |
| `displayTopN` | number | Quanti utenti mostrare (1–100, default: 10) |
| `showRank` | boolean | Se visualizzare i numeri di posizione (default: true) |
| `showScore` | boolean | Se visualizzare i valori del punteggio (default: true) |
| `defaultLang` | lang | Codice lingua predefinito |
| `langs` | lang[] | Lingue supportate (minimo 1) |

### Specifica della query

Il campo `query` contiene una definizione dichiarativa dell'intero calcolo della classifica — idoneità degli utenti, aggregazione delle metriche, calcolo del punteggio e ordinamento. Utilizza un linguaggio di query basato su JSONLogic che viene mappato in SQL al momento dell'esecuzione.

Una specifica di query definisce:

- **FROM / WHERE**: Quali utenti sono idonei per la leaderboard (es. solo utenti attivi, utenti con un tag specifico).
- **WITH (aggregations)**: Come aggregare le metriche — tipicamente transazioni di valuta virtuale, conteggi di attività o altri dati misurabili. Supporta raggruppamento, somma, conteggio e aggregazioni personalizzate.
- **SELECT**: Quali campi includere nell'output e come calcolare il punteggio finale. Supporta espressioni aritmetiche (es. `points * weight + bonus`).
- **ORDER BY**: Come classificare gli utenti (tipicamente per punteggio decrescente).
- **LIMIT**: Numero massimo di utenti da includere.

Questa architettura significa che le configurazioni delle leaderboard possono definire formule di punteggio arbitrarie — non solo semplici somme, ma calcoli ponderati, aggregazioni filtrate ed espressioni condizionali.

### Impostazioni di visualizzazione

I campi `displayTopN`, `showRank` e `showScore` controllano la presentazione frontend:

- `displayTopN: 10` mostra i primi 10 utenti.
- `showRank: false` nasconde i numeri di posizione (utile per leaderboard collaborative dove la posizione non è il focus principale).
- `showScore: false` nasconde il punteggio grezzo (utile quando l'ordine in classifica conta ma i numeri esatti sono interni).

## Runtime Leaderboard (istanza)

Un **Runtime Leaderboard** è un'istanza specifica che rappresenta un periodo di una leaderboard. Fa riferimento a una configurazione e aggiunge limiti temporali e stato.

### Campi

| Field | Type | Description |
|-------|------|-------------|
| `runtimeLeaderboardId` | nanoid | Identificatore univoco |
| `runtimeLeaderboardConfigurationId` | nanoid | Riferimento alla configurazione |
| `periodId` | string | Chiave di deduplicazione per questo periodo |
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Ambito temporale |
| `timeframeStartsAt` | ISO datetime | Quando inizia questo periodo |
| `timeframeEndsAt` | ISO datetime? | Quando termina (obbligatorio per RANGE/RECURRING) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Strategia di fuso orario |
| `timeframeTimezone` | timezone? | Fuso orario IANA (obbligatorio quando FIXED) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Stato del ciclo di vita |
| `recurrence` | `DAILY` \| `WEEKLY` \| `MONTHLY` \| `CUSTOM`? | Cadenza di reset (obbligatorio per RECURRING) |

### Identificazione del periodo

Il `periodId` funge da chiave di deduplicazione che codifica i limiti temporali:

| Timeframe | Formato periodId | Esempio |
|-----------|----------------|---------|
| `PERMANENT` | `"{startsAt}-"` | `2025-01-01T00:00:00.000Z-` |
| `RANGE` | `"{startsAt}-{endsAt}"` | `2025-01-01T00:00:00.000Z-2025-12-31T23:59:59.999Z` |
| `RECURRING` | `"{recurrence}-{startsAt}-{endsAt}"` | `WEEKLY-2025-01-06T00:00:00.000Z-2025-01-12T23:59:59.999Z` |

Questo formato garantisce che ogni periodo produca un identificatore univoco e leggibile.

### Ciclo di vita dello stato

```
              il tempo passa
                 │
    ┌────────────▼────────────┐
    │         PENDING         │  ◀── prima di timeframeStartsAt
    └────────────┬────────────┘
                 │ timeframeStartsAt raggiunto
                 ▼
    ┌────────────────────────┐
    │         ACTIVE          │  ◀── le classifiche vengono calcolate e visualizzate
    └────────────┬────────────┘
                 │ timeframeEndsAt raggiunto (non per PERMANENT)
                 ▼
    ┌────────────────────────┐
    │          ENDED          │  ◀── classifiche congelate
    └─────────────────────────┘
```

- **PENDING**: L'istanza esiste ma il suo periodo non è ancora iniziato. Le classifiche non sono disponibili.
- **ACTIVE**: Le classifiche vengono calcolate in tempo reale dalla query della configurazione. Gli utenti possono visualizzare la propria posizione.
- **ENDED**: Il periodo si è concluso. Le classifiche sono congelate come risultati storici.

Le transizioni di stato sono gestite da eventi schedulati che si attivano esattamente ai tempi `timeframeStartsAt` e `timeframeEndsAt`.

### Gestione dei fusi orari

Le leaderboard supportano due strategie di fuso orario che influenzano quando avvengono le transizioni di stato:

**FIXED** — Tutti gli utenti sperimentano le transizioni allo stesso tempo assoluto. Il campo `timeframeTimezone` specifica quale fuso orario utilizzare per interpretare i limiti. Esempio: una leaderboard settimanale in `"Europe/Rome"` si resetta a mezzanotte ora di Roma per tutti, indipendentemente dalla posizione dell'utente.

**USER** — Le transizioni sono relative al fuso orario locale di ciascun utente. Il sistema utilizza fusi orari estremi per determinare la finestra attiva globale:
- L'istanza diventa ACTIVE quando il _primo_ utente a livello globale entra nel periodo (UTC+14, il fuso orario più anticipato).
- L'istanza diventa ENDED quando l'_ultimo_ utente a livello globale esce dal periodo (UTC-12, il fuso orario più ritardato).
- Questo garantisce che tutti gli utenti vedano uno stato coerente, anche se la loro "mezzanotte di lunedì" locale avviene in momenti assoluti diversi.

La modalità USER crea una finestra attiva più ampia (fino a 26 ore in più rispetto alla modalità FIXED) ma garantisce equità tra i fusi orari.

## Come funzionano le leaderboard ricorrenti

Le leaderboard ricorrenti creano automaticamente nuove istanze quando il periodo corrente termina:

1. Un'istanza RECURRING transita da ACTIVE a ENDED.
2. Il sistema calcola i limiti del periodo successivo utilizzando il pattern di ricorrenza:
   - **DAILY**: prossimo inizio = inizio corrente + 1 giorno
   - **WEEKLY**: prossimo inizio = inizio corrente + 7 giorni
   - **MONTHLY**: prossimo inizio = inizio corrente + 1 mese
   - **CUSTOM**: prossimo inizio = fine corrente (periodi consecutivi con la stessa durata)
3. Un controllo di deduplicazione verifica che non esista già un'istanza per il prossimo `periodId`.
4. Se libero, viene creata una nuova istanza con `state: PENDING`.
5. La nuova istanza attiva le proprie transizioni di stato schedulate (ACTIVATION a `timeframeStartsAt`, DEACTIVATION a `timeframeEndsAt`).
6. La catena continua indefinitamente fino a quando la configurazione viene archiviata.

```
Instance 1              Instance 2              Instance 3
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Jan 1–7    │  ends   │  Jan 8–14   │  ends   │  Jan 15–21  │
│  ACTIVE     │ ──────▶ │  PENDING    │ ──────▶ │  PENDING    │
│             │ creates │  → ACTIVE   │ creates │  → ACTIVE   │
│  → ENDED   │         │  → ENDED   │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
```

## Come vengono calcolate le classifiche

Le classifiche vengono calcolate al momento della query — non pre-calcolate. Quando un utente richiede la leaderboard:

1. Il sistema verifica che l'istanza sia `ACTIVE`.
2. La `query` (QuerySpec) della configurazione viene caricata.
3. La query viene eseguita sul data store analitico del workspace (D1/SQLite), limitata ai confini temporali dell'istanza.
4. I risultati vengono ordinati secondo la specifica ORDER BY.
5. Viene applicata la paginazione (offset + limit).
6. La posizione in classifica dell'utente richiedente viene estratta e restituita insieme alla lista dei primi N.

Questo approccio garantisce che le classifiche riflettano sempre i dati più aggiornati senza ritardi di sincronizzazione.

## Segmentazione

La specifica della query della configurazione consente qualsiasi segmentazione tramite la sua clausola WHERE e le definizioni JOIN:

- **Leaderboard globali**: includono tutti gli utenti nel workspace.
- **Leaderboard di community**: filtrano gli utenti per tag di reparto, team o regione.
- **Leaderboard di missione**: limitate agli utenti che partecipano a una specifica missione.
- **Segmenti personalizzati**: qualsiasi combinazione di attributi utente e tag.

Poiché la query è completamente configurabile, i client possono creare esperienze competitive mirate per qualsiasi contesto.

## Esempio: leaderboard settimanale per reparto

### Passaggio 1: configurazione

Una configurazione definisce: _"Classifica gli utenti attivi per XP totali guadagnati, raggruppati per tag di reparto."_

```json
{
  "runtimeLeaderboardConfigurationId": "rlc-weekly-xp",
  "name": "Weekly XP Leaderboard",
  "displayTopN": 10,
  "showRank": true,
  "showScore": true,
  "query": {
    "from": { "table": "users" },
    "with": [{
      "name": "user_xp",
      "select": [
        { "expression": { "var": "userId" }, "alias": "userId" },
        { "expression": { "sum": [{ "var": "amount" }] }, "alias": "totalXp" }
      ],
      "from": "virtual_transactions",
      "where": { "===": [{ "var": "virtualCurrencyId" }, "vc-xp"] },
      "groupBy": ["userId"]
    }],
    "select": [
      { "expression": { "var": "userId" }, "alias": "entityId" },
      { "expression": { "var": "totalXp" }, "alias": "score" }
    ],
    "orderBy": [{ "expression": "score", "direction": "DESC" }]
  }
}
```

### Passaggio 2: prima istanza

Creare un'istanza settimanale ricorrente:

```json
{
  "runtimeLeaderboardId": "rl-week-1",
  "runtimeLeaderboardConfigurationId": "rlc-weekly-xp",
  "timeframeType": "RECURRING",
  "recurrence": "WEEKLY",
  "timeframeStartsAt": "2025-01-06T00:00:00Z",
  "timeframeEndsAt": "2025-01-12T23:59:59Z",
  "timeframeTimezoneType": "FIXED",
  "timeframeTimezone": "Europe/Rome",
  "periodId": "WEEKLY-2025-01-06T00:00:00.000Z-2025-01-12T23:59:59.000Z",
  "state": "PENDING"
}
```

### Passaggio 3: cosa succede a runtime

1. **Mezzanotte di lunedì (Roma)**: Lo stato transita ad ACTIVE. Gli utenti possono consultare le classifiche.
2. **Durante la settimana**: Gli utenti guadagnano XP. Le classifiche si aggiornano in tempo reale.
3. **Mezzanotte di domenica (Roma)**: Lo stato transita a ENDED. Le classifiche vengono congelate.
4. **Immediatamente dopo**: Viene creata una nuova istanza per il 13–19 gennaio con `state: PENDING`.
5. **Mezzanotte di lunedì**: La nuova istanza si attiva. Il ciclo continua.

## Riepilogo dei concetti chiave

| Concetto | Scopo |
|----------|-------|
| **RuntimeLeaderboardConfiguration** | Template che definisce _cosa_ classificare (query, impostazioni di visualizzazione) |
| **RuntimeLeaderboard** | Istanza che rappresenta _un periodo_ con intervallo temporale e stato |
| **QuerySpec** | Calcolo dichiarativo della classifica (idoneità, aggregazione, punteggio, ordinamento) |
| **periodId** | Chiave di deduplicazione che codifica i limiti temporali |
| **Catena ricorrente** | Le istanze ENDED creano automaticamente l'istanza del periodo successivo |
| **Calcolo al momento della query** | Le classifiche riflettono sempre i dati correnti, nessuna cache obsoleta |
| **Fuso orario FIXED vs USER** | Stesso tempo assoluto vs. limiti locali dell'utente (finestra attiva più ampia) |
| **displayTopN / showRank / showScore** | Controlli di presentazione frontend |

## Domini correlati

- **Dominio Reward e Currency**: le classifiche classificano gli utenti in base all'accumulo di valuta virtuale (es. XP guadagnati tramite regole di ricompensa).
- **Dominio Mission**: il completamento delle missioni attiva l'erogazione di ricompense che alimentano i punteggi delle classifiche.
- **Dominio Streak**: l'engagement basato sulle streak può contribuire alle metriche delle classifiche attraverso le ricompense in valuta virtuale.
- **Cross-Cutting Patterns**: timeframe, ciclo di vita degli stati (PENDING→ACTIVE→ENDED) e pattern di gestione dei fusi orari utilizzati in tutto questo dominio.
