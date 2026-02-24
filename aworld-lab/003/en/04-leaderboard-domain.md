The leaderboard system turns virtual currency accumulation into competitive rankings. It answers questions like _"Who are the top 10 users in the marketing department this week?"_ and _"What is my current rank?"_

This section covers the full leaderboard model: configuration templates, query-based ranking computation, recurring instance chains, and timezone handling. It is relevant for anyone setting up competitive mechanics or integrating leaderboards via API. For a high-level overview, see the Gamification Fundamentals. For shared patterns (timeframes, state lifecycle), see Cross-Cutting Patterns.

The domain is built on a two-layer architecture that separates _what_ is ranked from _when_ it is ranked:

```
RuntimeLeaderboardConfiguration  (the template: what to compute)
      │
      └──▶ RuntimeLeaderboard  (the instance: a specific period and its state)
```

A single configuration can power multiple runtime instances. For example, a "Top Points This Week" configuration automatically generates a new weekly instance every Monday, each with independent rankings.

## Runtime Leaderboard Configuration

A **Configuration** defines _what_ the leaderboard computes: which users are eligible, how scores are calculated, and how results are displayed.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `runtimeLeaderboardConfigurationId` | nanoid | Unique identifier |
| `name` | string | Human-readable name |
| `description` | string? | Optional description |
| `query` | QuerySpec | The complete ranking computation definition |
| `displayTopN` | number | How many users to show (1–100, default: 10) |
| `showRank` | boolean | Whether to display rank numbers (default: true) |
| `showScore` | boolean | Whether to display score values (default: true) |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (min 1) |

### Query Specification

The `query` field contains a declarative definition of the entire ranking computation — user eligibility, metric aggregation, score calculation, and sort order. It uses a JSONLogic-based query language that maps to SQL at execution time.

A query specification defines:

- **FROM / WHERE**: Which users are eligible for the leaderboard (e.g., active users only, users with a specific tag).
- **WITH (aggregations)**: How to aggregate metrics — typically virtual currency transactions, activity counts, or other measurable data. Supports grouping, summing, counting, and custom aggregations.
- **SELECT**: Which fields to include in the output and how to compute the final score. Supports arithmetic expressions (e.g., `points * weight + bonus`).
- **ORDER BY**: How to rank users (typically by score descending).
- **LIMIT**: Maximum number of users to include.

This architecture means leaderboard configurations can define arbitrary scoring formulas — not just simple sums, but weighted calculations, filtered aggregations, and conditional expressions.

### Display Settings

The `displayTopN`, `showRank`, and `showScore` fields control the frontend presentation:

- `displayTopN: 10` shows the top 10 users.
- `showRank: false` hides position numbers (useful for collaborative leaderboards where rank isn't the focus).
- `showScore: false` hides the raw score (useful when the ranking order matters but the exact numbers are internal).

## Runtime Leaderboard (Instance)

A **Runtime Leaderboard** is a specific instance that represents one period of a leaderboard. It references a configuration and adds temporal boundaries and state.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `runtimeLeaderboardId` | nanoid | Unique identifier |
| `runtimeLeaderboardConfigurationId` | nanoid | References the configuration |
| `periodId` | string | Deduplication key for this period |
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Temporal scope |
| `timeframeStartsAt` | ISO datetime | When this period begins |
| `timeframeEndsAt` | ISO datetime? | When it ends (required for RANGE/RECURRING) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Timezone strategy |
| `timeframeTimezone` | timezone? | IANA timezone (required when FIXED) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Lifecycle state |
| `recurrence` | `DAILY` \| `WEEKLY` \| `MONTHLY` \| `CUSTOM`? | Reset cadence (required for RECURRING) |

### Period Identification

The `periodId` serves as a deduplication key that encodes the timeframe boundaries:

| Timeframe | periodId Format | Example |
|-----------|----------------|---------|
| `PERMANENT` | `"{startsAt}-"` | `2025-01-01T00:00:00.000Z-` |
| `RANGE` | `"{startsAt}-{endsAt}"` | `2025-01-01T00:00:00.000Z-2025-12-31T23:59:59.999Z` |
| `RECURRING` | `"{recurrence}-{startsAt}-{endsAt}"` | `WEEKLY-2025-01-06T00:00:00.000Z-2025-01-12T23:59:59.999Z` |

This format ensures that each period produces a unique, human-readable identifier.

### State Lifecycle

```
              time passes
                 │
    ┌────────────▼────────────┐
    │         PENDING         │  ◀── before timeframeStartsAt
    └────────────┬────────────┘
                 │ timeframeStartsAt reached
                 ▼
    ┌────────────────────────┐
    │         ACTIVE          │  ◀── rankings are computed and displayed
    └────────────┬────────────┘
                 │ timeframeEndsAt reached (not for PERMANENT)
                 ▼
    ┌────────────────────────┐
    │          ENDED          │  ◀── rankings frozen
    └─────────────────────────┘
```

- **PENDING**: The instance exists but its period hasn't started. Rankings are not available.
- **ACTIVE**: Rankings are computed in real time from the configuration's query. Users can view their position.
- **ENDED**: The period has concluded. Rankings are frozen as historical results.

State transitions are managed by scheduled events that fire at the exact `timeframeStartsAt` and `timeframeEndsAt` times.

### Timezone Handling

Leaderboards support two timezone strategies that affect when state transitions occur:

**FIXED** — All users experience transitions at the same absolute time. The `timeframeTimezone` field specifies which timezone to use for interpreting boundaries. Example: a weekly leaderboard in `"Europe/Rome"` resets at midnight Rome time for everyone, regardless of the user's location.

**USER** — Transitions are relative to each user's local timezone. The system uses extreme timezones to determine the global active window:
- The instance becomes ACTIVE when the _first_ user globally enters the period (UTC+14, the earliest timezone).
- The instance becomes ENDED when the _last_ user globally exits the period (UTC-12, the latest timezone).
- This ensures all users see a consistent state, even though their local "Monday midnight" happens at different absolute times.

The USER mode creates a wider active window (up to 26 hours wider than FIXED mode) but guarantees fairness across timezones.

## How Recurring Leaderboards Work

Recurring leaderboards automatically create new instances when the current period ends:

1. A RECURRING instance transitions from ACTIVE to ENDED.
2. The system calculates the next period's boundaries using the recurrence pattern:
   - **DAILY**: next start = current start + 1 day
   - **WEEKLY**: next start = current start + 7 days
   - **MONTHLY**: next start = current start + 1 month
   - **CUSTOM**: next start = current end (back-to-back periods with the same duration)
3. A deduplication check verifies no instance already exists for the next `periodId`.
4. If clear, a new instance is created with `state: PENDING`.
5. The new instance triggers its own scheduled state transitions (ACTIVATION at `timeframeStartsAt`, DEACTIVATION at `timeframeEndsAt`).
6. The chain continues indefinitely until the configuration is archived.

```
Instance 1              Instance 2              Instance 3
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│  Jan 1–7    │  ends   │  Jan 8–14   │  ends   │  Jan 15–21  │
│  ACTIVE     │ ──────▶ │  PENDING    │ ──────▶ │  PENDING    │
│             │ creates │  → ACTIVE   │ creates │  → ACTIVE   │
│  → ENDED   │         │  → ENDED   │         │             │
└─────────────┘         └─────────────┘         └─────────────┘
```

## How Rankings Are Computed

Rankings are computed at query time — not pre-calculated. When a user requests the leaderboard:

1. The system verifies the instance is `ACTIVE`.
2. The configuration's `query` (QuerySpec) is loaded.
3. The query is executed against the workspace's analytical data store (D1/SQLite), scoped to the instance's timeframe boundaries.
4. Results are sorted according to the ORDER BY specification.
5. Pagination is applied (offset + limit).
6. The requesting user's own rank is extracted and returned alongside the top N list.

This approach ensures rankings always reflect the most current data without synchronization delays.

## Segmentation

The configuration's query specification enables any segmentation through its WHERE clause and JOIN definitions:

- **Global leaderboards**: include all users in the workspace.
- **Community leaderboards**: filter users by department, team, or region tags.
- **Mission leaderboards**: scope to users participating in a specific mission.
- **Custom segments**: any combination of user attributes and tags.

Because the query is fully configurable, clients can create targeted competitive experiences for any context.

## Example: Weekly Department Leaderboard

### Step 1: Configuration

A configuration defines: _"Rank active users by total XP earned, grouped by department tag."_

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

### Step 2: First Instance

Create a recurring weekly instance:

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

### Step 3: What Happens at Runtime

1. **Monday midnight (Rome)**: State transitions to ACTIVE. Users can query rankings.
2. **Throughout the week**: Users earn XP. Rankings update in real time.
3. **Sunday midnight (Rome)**: State transitions to ENDED. Rankings are frozen.
4. **Immediately after**: A new instance is created for Jan 13–19 with `state: PENDING`.
5. **Monday midnight**: The new instance activates. Cycle continues.

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **RuntimeLeaderboardConfiguration** | Template defining _what_ to rank (query, display settings) |
| **RuntimeLeaderboard** | Instance representing _one period_ with timeframe and state |
| **QuerySpec** | Declarative ranking computation (eligibility, aggregation, scoring, sorting) |
| **periodId** | Deduplication key encoding timeframe boundaries |
| **Recurring chain** | ENDED instances automatically create the next period's instance |
| **Query-time computation** | Rankings always reflect current data, no stale caches |
| **FIXED vs USER timezone** | Same absolute time vs. user-local boundaries (wider active window) |
| **displayTopN / showRank / showScore** | Frontend presentation controls |

## Related Domains

- **Reward & Currency Domain**: leaderboards rank users by virtual currency accumulation (e.g., XP earned via reward rules).
- **Mission Domain**: mission completion triggers reward payouts that feed leaderboard scores.
- **Streak Domain**: streak-based engagement can contribute to leaderboard metrics through virtual currency rewards.
- **Cross-Cutting Patterns**: timeframes, state lifecycle (PENDING→ACTIVE→ENDED), and timezone handling patterns used throughout this domain.
