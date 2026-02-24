AWorld Lab's domain services share a set of architectural patterns that recur across missions, streaks, learning paths, rewards, and leaderboards. This document describes each pattern once so that the domain-specific deep-dives can reference it rather than repeat it.

## JsonLogic Expression System

Several fields across the platform accept **JsonLogic expressions** — JSON-encoded rules that are evaluated at runtime against a context object. This allows clients to define complex conditions, calculations, and filters through configuration alone.

### How It Works

A JsonLogic expression is a JSON object where keys are operators and values are arguments. The platform evaluates the expression against a context object that contains the relevant data for that evaluation point.

```json
// "Is the event's progress equal to COMPLETE?"
{ "===": [{ "var": "event.progress" }, "COMPLETE"] }

// "Award 20 points for HARD quizzes, 10 for MEDIUM, 5 for EASY"
{
  "if": [
    { "===": [{ "var": "event.difficulty" }, "HARD"] }, 20,
    { "===": [{ "var": "event.difficulty" }, "MEDIUM"] }, 10,
    5
  ]
}

// Compound condition
{
  "and": [
    { "===": [{ "var": "event.progress" }, "COMPLETE"] },
    { "===": [{ "var": "event.outcome" }, "SUCCESS"] }
  ]
}
```

The platform extends the standard JsonLogic library with `Math` operations (`sqrt`, `pow`, `min`, `max`, etc.) and `Date` access.

### Where It Is Used

| Domain | Expression Field | Context Object | Purpose |
|--------|-----------------|----------------|---------|
| **MissionConfiguration** | `matchCondition` | `{ mission }` | Filter which events count toward progress |
| **MissionConfiguration** | `incrementExpression` | `{ user, event }` | Calculate how much progress each event adds |
| **MissionConfiguration** | `targetAmountExpression` | `{ user, mission }` | Calculate the completion target |
| **MissionRule** | `usersMatchCondition` | `{ user }` | Determine which users are eligible |
| **MissionRule** | `missionsMatchCondition` | `{ mission }` | Filter which configurations to instantiate |
| **MissionRule** | `eventMatchCondition` | event data | Filter which events trigger assignment (EVENT mode) |
| **StreakConfiguration** | `matchCondition` | `{ event }` | Determine if an event counts toward a streak |
| **StreakRule** | `usersMatchCondition` | `{ user }` | Determine which users this rule applies to |
| **StreakRule** | `freezeCostExpression` | `{ user, streak }` | Calculate the virtual currency cost to freeze |
| **LearningPathRule** | `usersMatchCondition` | `{ user, activeAssignments }` | Determine user eligibility |
| **LearningPathRule** | `learningPathsMatchCondition` | `{ user, learningPath }` | Filter which paths to assign |
| **LearningPathRule** | `initialVisibilityCondition` | `{ learningPath, index, user }` | Determine LOCKED or UNLOCKED per path |
| **LearningPathRule** | `eventMatchCondition` | event data | Filter which events trigger UNLOCK |
| **RewardRule** | `matchCondition` | `{ event, previousEvent }` | Determine if an event qualifies for a reward |
| **RewardRule** | reward `expression` | `{ event }` | Calculate the reward amount |

### Important Behaviors

- A static value (e.g., `true`, `100`) is a valid expression — it always returns that value.
- Missing fields in the context return `null`. Expressions should handle this gracefully.
- Numeric results are force-cast to numbers; negative values in cost expressions are automatically inverted to ensure a positive cost.
- Expressions are stored as opaque JSON — the platform validates JSON syntax but does not validate expression semantics at write time.

---

## Configuration → Rule → Instance Pattern

Three major domains follow a three-layer hierarchy where a **Configuration** defines _what_ to track, a **Rule** defines _when and for whom_, and an **Instance** tracks _per-user state_:

```
Configuration  (what counts)
      │
      └──▶ Rule  (the rules of the game: who, when, how)
              │
              └──▶ Instance  (per-user or per-group tracking record)
```

| Layer | Mission Domain | Streak Domain | Learning Path Domain |
|-------|---------------|---------------|---------------------|
| Configuration | MissionConfiguration | StreakConfiguration | _(embedded in LearningPath)_ |
| Rule | MissionRule | StreakRule | LearningPathRule |
| Instance | Mission | Streak | LearningPathAssignment |
| Log | MissionLog | StreakLog | LearningPathLog |

Each layer has its own lifecycle, and changes at the Configuration or Rule level do not retroactively alter existing Instances — they only affect future assignments.

---

## Entity Matching Pattern

Multiple services use a consistent **three-mode matching system** to determine which entities are relevant to a rule or configuration:

### Match Types

| Match Type | Behavior | `matchEntityId` Required |
|-----------|----------|--------------------------|
| `INSTANCE` | Matches a _specific_ entity by ID. Example: completing activity `abc123`. | Yes |
| `ENTITY` | Matches _any_ entity of the given type. Example: completing any quiz. | No |
| `TAG` | Matches any entity tagged with the given tag. Example: any activity tagged `christmas`. | Yes (the tag ID) |

### Match Entities by Domain

| Domain | Available Match Entities |
|--------|------------------------|
| MissionConfiguration | `Activity`, `Quiz`, `Tag` |
| StreakConfiguration | `Mission`, `Activity`, `Quiz`, `Tag` |
| RewardRule | `Mission`, `Activity`, `Quiz`, `Tag`, `LearningPath`, `LearningGroup`, `Slide` |

> **Constraint**: When `matchType` is `INSTANCE` or `TAG`, the `matchEntityId` field is required. When `matchType` is `ENTITY`, `matchEntityId` must be absent.

The `TAG` match type is particularly powerful — by combining it with a `matchCondition` JsonLogic expression, you can create highly targeted rules like _"only activities tagged `christmas` that were completed in December"_.

---

## Timeframe and Scheduling

Rules and runtime instances share a common timeframe model that controls when they are active.

### Timeframe Types

| Type | Behavior | `timeframeEndsAt` |
|------|----------|-------------------|
| `PERMANENT` | Starts at `timeframeStartsAt`, runs indefinitely | Not required |
| `RANGE` | Active between `timeframeStartsAt` and `timeframeEndsAt`, once | Required |
| `RECURRING` | Repeats at a defined cadence between start and end dates | Required |

### Recurrence

When `timeframeType` is `RECURRING`, the `recurrence` field defines the reset cadence:

| Recurrence | Behavior |
|-----------|----------|
| `DAILY` | Resets every day |
| `WEEKLY` | Resets every week |
| `MONTHLY` | Resets every month |
| `CUSTOM` | Resets according to a cron expression (`scheduleCron`) |

> **Constraint**: `scheduleCron` is only required when `recurrence` is `CUSTOM`. The cron expression uses the standard IANA format.

### Timezone Handling

| Timezone Type | Behavior | `timeframeTimezone` |
|--------------|----------|---------------------|
| `FIXED` | All users experience transitions at the same absolute time | Required (IANA timezone, e.g., `"Europe/Rome"`) |
| `USER` | Each user's transitions are relative to their local timezone | Not required |

`USER` timezone is ideal for daily/weekly rules where fairness requires each user to have the same local boundaries. `FIXED` timezone is appropriate for global events that must start and end simultaneously for everyone.

### Services Using This Pattern

MissionRule, StreakRule, LearningPathRule, RuntimeLeaderboard — all use the same field names and the same set of valid values.

---

## State Lifecycle

Entities with a timeframe follow a consistent three-state lifecycle:

```
              time passes
                 │
    ┌────────────▼────────────┐
    │         PENDING         │  ◀── before timeframeStartsAt
    └────────────┬────────────┘
                 │ timeframeStartsAt reached
                 ▼
    ┌────────────────────────┐
    │         ACTIVE          │  ◀── between start and end
    └────────────┬────────────┘
                 │ timeframeEndsAt reached (not for PERMANENT)
                 ▼
    ┌────────────────────────┐
    │          ENDED          │  ◀── after timeframeEndsAt
    └─────────────────────────┘
```

- **PENDING**: The entity exists but is not yet operational. It was created ahead of its start time.
- **ACTIVE**: The entity is operational and accepting interactions.
- **ENDED**: The entity's timeframe has passed. Terminal state.

> **Note**: `PERMANENT` entities never reach `ENDED` — they remain `ACTIVE` indefinitely once started.

State transitions are managed by scheduled processes that periodically evaluate each entity's timeframe and update the state accordingly. The calculation is deterministic: given the current time and the timeframe fields, the state can always be derived.

---

## Multi-Language and Localization

All content-bearing entities support multiple languages through a consistent pattern.

### Language Fields on the Main Entity

| Field | Type | Description |
|-------|------|-------------|
| `defaultLang` | language code | The primary language for this entity |
| `langs` | language code[] | All supported languages (1 to 10) |

### Translation Entities

Translatable content is stored in separate **Translation** entities rather than embedded in the main entity. Each translation is keyed by the parent entity's ID plus a `lang` field.

```
LearningPath (defaultLang: "en", langs: ["en", "it", "fr"])
      │
      ├── LearningPathTranslation (lang: "en", title: "Onboarding", description: "...")
      ├── LearningPathTranslation (lang: "it", title: "Onboarding", description: "...")
      └── LearningPathTranslation (lang: "fr", title: "Intégration", description: "...")
```

Typical translatable fields include `title`, `description`, and `image` (for language-specific imagery). Each domain defines its own set of translatable fields.

### Translation History

Configuration entities that support audit trails also maintain **TranslationHistory** records, providing full versioning of translated content.

### Services Using This Pattern

MissionConfiguration, MissionRule, StreakConfiguration, StreakRule, RewardRule, LearningPath, LearningGroup, Quiz, Slide, Activity, VirtualCurrency, RuntimeLeaderboardConfiguration.

---

## Origin and Catalog Sync

Content and configuration entities track their **origin** — whether they were created from a catalog template, generated by AI, or defined custom by the client.

### Origin Values

| Origin | Description |
|--------|-------------|
| `CATALOG` | Created from a pre-built template in the catalog workspace |
| `CUSTOM` | Created from scratch by the client |
| `AI` | Generated by AI content creation (Learning Paths and Learning Groups only) |

### Catalog Reference Fields

When `origin` is `CATALOG`, the entity stores a reference back to its catalog source:

| Field Pattern | Example |
|--------------|---------|
| `catalog<Entity>Id` | `catalogMissionRuleId`, `learningPathCatalogId`, `catalogRewardRuleId` |
| `syncWithCatalog` | Boolean — whether to keep the entity in sync with future catalog updates |

> **Constraint**: When `origin` is `CATALOG`, the catalog reference ID should be set. When `origin` is `CUSTOM`, it should be absent.

### Services Using This Pattern

MissionConfiguration, MissionRule, StreakConfiguration, StreakRule, RewardRule, LearningPath, LearningGroup, Quiz, Slide, Activity, VirtualCurrency.

---

## Tag System

Tags are a foundational cross-cutting mechanism used for categorization, targeting, and segmentation across the entire platform.

### Tag Structure

Each tag is defined by a **namespace** and **variant**:

- **Namespace**: the category (e.g., `department`, `region`, `tier`)
- **Variant**: the specific value (e.g., `marketing`, `europe`, `gold`)

### Tag Assignments

Tags can be assigned to virtually any entity — users, activities, quizzes, learning paths, learning groups, slides, mission configurations, mission rules, streak configurations, and streak rules. Each assignment includes a **priority** value for ordering.

### Tags in the Rule Engine

Tags serve three critical roles in the platform's rule systems:

1. **Entity matching**: Rules with `matchType: TAG` target all entities associated with a specific tag, enabling thematic grouping (e.g., all activities tagged `christmas`).
2. **User segmentation**: `usersMatchCondition` expressions can reference user tags to target specific user groups.
3. **Group targeting**: Group missions and community leaderboards are scoped by tag, enabling team-based and segment-based experiences.

---

## Summary

| Pattern | Purpose | Used By |
|---------|---------|---------|
| **JsonLogic** | Declarative conditions and calculations | All rule and configuration entities |
| **Config → Rule → Instance** | Hierarchical domain modeling | Mission, Streak, LearningPath |
| **Entity Matching** | Flexible event targeting (INSTANCE/ENTITY/TAG) | MissionConfig, StreakConfig, RewardRule |
| **Timeframe & Scheduling** | Temporal boundaries and recurrence | MissionRule, StreakRule, LPRule, Leaderboard |
| **State Lifecycle** | PENDING → ACTIVE → ENDED | All rule and instance entities |
| **Multi-Language** | Localized content via Translation entities | All content-bearing entities |
| **Origin & Catalog** | Template sourcing and sync | All configuration entities |
| **Tag System** | Categorization, targeting, segmentation | Cross-cutting across all domains |
