The reward system automatically distributes virtual currency when users perform actions. It answers questions like _"How many points should this user receive for completing a hard quiz?"_ and _"Does the user have enough credits to redeem this reward?"_

> This section covers the full reward model: rule evaluation with priority resolution (ALWAYS/FALLBACK), currency management, transaction lifecycle, and balance tracking. It is relevant for anyone configuring reward rules or integrating the virtual economy via API. For a high-level overview, see the Gamification Fundamentals. For shared patterns (JsonLogic expressions, entity matching), see Cross-Cutting Patterns.

The domain connects rule evaluation to a virtual economy:

```
RewardRule  (when and how much to award)
      │
      └──▶ VirtualTransaction  (a ledger entry: credit or debit)
                │
                └──▶ VirtualBalance  (the user's current balance per currency)
```

The virtual economy is powered by:

```
VirtualCurrency  (defines a currency: XP, credits, tokens, etc.)
```

## Reward Rule

A **Reward Rule** defines when virtual currency should be awarded and how much. Each rule watches for specific events (activity completion, quiz passed, mission completed, etc.) and generates transactions when conditions are met.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `rewardRuleId` | string | Unique identifier |
| `name` | string | Human-readable name |
| `ruleType` | `INSTANCE` \| `ENTITY` \| `TAG` | How to match events |
| `matchEntity` | enum | Which entity type triggers this rule (see below) |
| `matchEntityId` | string? | Specific entity or tag ID (required for INSTANCE and TAG) |
| `matchCondition` | JsonLogic | Additional event filtering |
| `applicationMode` | `ALWAYS` \| `FALLBACK` \| `DISABLED` | When this rule fires |
| `rewards` | Reward[] | 1–10 reward payouts |
| `origin` | `CATALOG` \| `CUSTOM` | Creation source |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (1–10) |

### Match Entities

Reward rules support the broadest set of match entities in the platform:

| Match Entity | Triggers On |
|-------------|-------------|
| `Mission` | Mission completion |
| `Activity` | Activity completion |
| `Quiz` | Quiz completion |
| `Tag` | Any entity with a matching tag |
| `LearningPath` | Learning path progress/completion |
| `LearningGroup` | Learning group progress/completion |
| `Slide` | Slide completion |

The match type works the same as in other domains:
- **`INSTANCE`**: matches a specific entity by ID.
- **`ENTITY`**: matches any entity of the given type.
- **`TAG`**: matches any entity with the given tag.

### Application Modes and Resolution Order

Application modes control the priority of rule evaluation:

**`ALWAYS`** — Primary rules. These are evaluated first and fire whenever their conditions are met.

**`FALLBACK`** — Backup rules. These fire _only if no ALWAYS rules matched_ for the same event. This prevents reward stacking while ensuring a baseline reward always exists.

**`DISABLED`** — Inactive rules. Not evaluated.

The resolution algorithm:

1. An event occurs (e.g., quiz completed).
2. The system queries all `ALWAYS` rules that match the event's entity type and ID (across INSTANCE, ENTITY, and TAG rule types).
3. For each rule, the `matchCondition` is evaluated against the event data.
4. If any ALWAYS rules match → use those rules. Done.
5. If no ALWAYS rules match → query `FALLBACK` rules, evaluate conditions, use those.
6. Never both — either ALWAYS rules fire or FALLBACK rules fire, not both.

This design enables patterns like:
- ALWAYS rule: "Award 20 XP for any HARD quiz" (specific).
- FALLBACK rule: "Award 5 XP for any quiz" (baseline, only when no specific rule applies).

### Match Condition

The `matchCondition` receives `{ event, previousEvent }` as context, where `previousEvent` is the entity's state before the current update. This enables conditions based on state transitions:

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

### Rewards Array

Each rule contains 1–10 reward definitions. A single rule can award multiple currencies simultaneously:

| Field | Type | Description |
|-------|------|-------------|
| `virtualCurrencyId` | nanoid | Which currency to award |
| `redemptionMode` | `AUTO` \| `MANUAL` | How the transaction is finalized |
| `expression` | JsonLogic | Evaluates to the amount to award |

**Redemption modes**:
- **`AUTO`**: The transaction is immediately completed — the user's balance is credited instantly. Typical for XP and automatic rewards.
- **`MANUAL`**: The transaction is created as PENDING and requires explicit action to redeem. Useful for prize redemption flows where the user must claim the reward.

**Expression examples**:

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

The expression receives `{ event }` as context. If it evaluates to `0` or a non-numeric value, the transaction is silently skipped.

### Event Remapping

Source events are remapped to their parent entity types before rule matching:

| Source Event | Maps To |
|-------------|---------|
| `ActivityLog` | `Activity` |
| `LearningPathLog` | `LearningPath` |
| `LearningGroupLog` | `LearningGroup` |
| `SlideLog` | `Slide` |

This means rules are defined against the parent entity (e.g., `matchEntity: "Activity"`), not against the log entity.

## Virtual Currency

A **Virtual Currency** defines a type of point, credit, or token within a workspace. Each workspace can have multiple currencies serving different purposes.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `virtualCurrencyId` | nanoid | Unique identifier |
| `name` | string | Display name |
| `icon` | URL? | Optional icon for UI |
| `minAllowedBalance` | number? | Optional floor for user balances |
| `maxAllowedBalance` | number? | Optional ceiling for user balances |
| `origin` | `CATALOG` \| `CUSTOM` | Creation source |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (1–10) |

### Typical Configurations

| Currency | Purpose | Balance Constraints |
|----------|---------|-------------------|
| Experience Points (XP) | Drives leaderboard rankings and levels | No cap (min: 0) |
| Credits | Earned and spent on rewards | Min: 0, optional max |
| Streak Tokens | Spent to freeze streaks | Min: 0 |

A common setup uses two currencies: **XP** for progression (cannot be spent) and **credits** for rewards (earned and redeemable). Clients can define any number of currencies.

## Virtual Transaction

A **Virtual Transaction** is a ledger entry recording a credit or debit to a user's virtual currency balance.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `virtualTransactionId` | nanoid | Unique identifier |
| `virtualTransactionGroupId` | nanoid | Groups related transactions together |
| `redemptionGroupId` | nanoid? | Groups redemptions |
| `userId` | nanoid | The user whose balance is affected |
| `virtualCurrencyId` | nanoid | Which currency |
| `direction` | `CREDIT` \| `DEBIT` | Adding or removing |
| `amount` | number | The amount (must not be zero) |
| `state` | `PENDING` \| `COMPLETED` \| `EXPIRED` \| `REJECTED` | Lifecycle state |
| `redemptionMode` | `AUTO` \| `MANUAL` | How finalization works |
| `initiatorType` | enum | What caused this transaction (see below) |
| `initiator` | string | Identifier of the initiator (e.g., `"rewardRuleId#rr-123"`) |
| `counterpartType` | `USER` \| `SYSTEM` | The other party |
| `counterpart` | string | Identifier of the counterpart |
| `expiresAt` | ISO datetime? | Optional expiration date |
| `redeemedAt` | string? | When the transaction was redeemed |
| `additionalData` | record? | Custom metadata |

### Initiator Types

| Initiator Type | Description |
|---------------|-------------|
| `USER` | Direct user action (e.g., spending credits) |
| `REWARD_RULE` | Automatic payout from a reward rule evaluation |
| `STREAK_RULE` | Deduction for streak freeze |
| `SYSTEM` | Automated system process |
| `ADMIN` | Administrator manual action |

### Transaction Lifecycle

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

- **PENDING**: The transaction exists but has not been applied to the balance yet.
- **COMPLETED**: The transaction is finalized and reflected in the balance.
- **EXPIRED**: The transaction was not redeemed before `expiresAt`. Terminal state.
- **REJECTED**: The transaction was denied (e.g., insufficient balance for a debit). Terminal state.

For `AUTO` redemption mode, the transaction transitions directly to COMPLETED upon creation. For `MANUAL`, it stays PENDING until the user or admin explicitly redeems it.

## Virtual Balance

A **Virtual Balance** tracks a user's current balance for a specific currency.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `userId` | nanoid | The user |
| `virtualCurrencyId` | nanoid | The currency |
| `amount` | number | Total balance (including pending transactions) |
| `availableAmount` | number | Balance available for spending (completed transactions only) |

### Amount vs. Available Amount

- **`amount`**: The total, including PENDING transactions. Represents what the user _will_ have if all pending transactions complete.
- **`availableAmount`**: Only COMPLETED transactions. Represents what the user _can spend right now_.

For `AUTO` redemption mode, `amount` and `availableAmount` are always equal (since transactions complete immediately). The difference only matters for `MANUAL` mode, where a reward might be pending user redemption.

## How Rewards Are Processed

When a user performs an action that might trigger rewards:

1. **Event arrives**: The source system (Activity, Quiz, LearningPath, etc.) publishes an event.
2. **Entity remapping**: `ActivityLog` → `Activity`, `LearningPathLog` → `LearningPath`, etc.
3. **Rule lookup**: The system queries for matching rules across all three rule types (INSTANCE, ENTITY, TAG) in parallel.
4. **ALWAYS/FALLBACK resolution**: If any ALWAYS rules match, use those. Otherwise, use FALLBACK rules.
5. **Condition evaluation**: Each rule's `matchCondition` is evaluated against `{ event, previousEvent }`.
6. **Transaction calculation**: For each matching rule, for each reward in the rule:
   - The reward `expression` is evaluated against `{ event }`.
   - If the result is a non-zero number, a transaction input is prepared.
   - If the result is zero or non-numeric, the reward is skipped.
7. **Transaction creation**: Virtual transactions are created in the database.
8. **Balance update**: For AUTO transactions, the user's balance is updated immediately.

### Example: Multi-Currency Reward Rule

A single rule that awards both XP and credits for completing a learning path:

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

When any learning path is completed: 50 XP + 100 credits are instantly credited.

### Example: Dynamic Difficulty-Based Rewards

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

### Example: FALLBACK Baseline

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

If a premium-tagged activity is completed → 20 XP (ALWAYS rule fires, FALLBACK skipped).
If a non-tagged activity is completed → 5 XP (no ALWAYS rules match, FALLBACK fires).

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **RewardRule** | Defines when and how much currency to award (7 match entities, ALWAYS/FALLBACK resolution) |
| **VirtualCurrency** | Defines a currency type with optional balance constraints |
| **VirtualTransaction** | Ledger entry: CREDIT or DEBIT, with lifecycle (PENDING→COMPLETED/EXPIRED/REJECTED) |
| **VirtualBalance** | User's current balance per currency (total vs. available) |
| **applicationMode** | `ALWAYS` (primary) vs `FALLBACK` (backup if no ALWAYS matched) vs `DISABLED` |
| **rewards array** | 1–10 payouts per rule, each with a currency, mode, and expression |
| **redemptionMode** | `AUTO` (instant) vs `MANUAL` (requires explicit redemption) |
| **initiatorType** | What caused the transaction: `USER`, `REWARD_RULE`, `STREAK_RULE`, `SYSTEM`, `ADMIN` |
| **Event remapping** | Log entities (ActivityLog, etc.) are mapped to parent entities for rule matching |
| **previousEvent** | Enables transition-based conditions ("only reward when progress changes to COMPLETE") |

## Related Domains

- **Mission Domain**: mission completion is one of the key events that triggers reward rules.
- **Learning Content Domain**: learning path and learning group completions trigger reward payouts.
- **Streak Domain**: the freeze mechanism deducts virtual currency to preserve streaks.
- **Leaderboard Domain**: leaderboards rank users by virtual currency accumulation (e.g., XP).
- **Cross-Cutting Patterns**: JsonLogic expressions and entity matching patterns used throughout this domain.
