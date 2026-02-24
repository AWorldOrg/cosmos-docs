The streak system tracks user engagement over time. It answers questions like _"Has this user been active every day for the past 30 days?"_ or _"How many weeks in a row has this user completed at least one quiz?"_

> This section covers the full streak model: configuration and matching, cadence and metric dimensions, goal tracking, freeze mechanics, and the record system. It is relevant for anyone configuring engagement streaks or integrating them via API. For a high-level overview, see the Gamification Fundamentals. For shared patterns (JsonLogic expressions, timeframes, entity matching), see Cross-Cutting Patterns.

The domain is built around three entities that form a clear hierarchy:

```
StreakConfiguration  (what counts)
      │
      └──▶ StreakRule  (the rules of the game)
                │
                └──▶ Streak  (per-user tracking records)
```

## Streak Configuration

A **Streak Configuration** defines _what user actions count_ toward a streak. It is the matching layer that connects domain events (completing an activity, finishing a quiz, etc.) to the streak system.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `streakConfigurationId` | nanoid | Unique identifier |
| `matchType` | `INSTANCE` \| `ENTITY` \| `TAG` | How to match incoming events |
| `matchEntity` | `Mission` \| `Activity` \| `Quiz` \| `Tag` | Which entity type to watch |
| `matchEntityId` | string? | Specific entity or tag ID (required for `INSTANCE` and `TAG`) |
| `matchCondition` | JsonLogic | Additional matching logic evaluated at runtime |

### Match Types

- **`INSTANCE`**: Matches a _specific_ entity. Example: completing activity `abc123`. Requires `matchEntityId`.
- **`ENTITY`**: Matches _any_ entity of that type. Example: completing any quiz.
- **`TAG`**: Matches any entity tagged with the given tag. Example: completing any activity tagged `christmas`. Requires `matchEntityId` (the tag ID).

This is where the flexibility lives. By combining `TAG` matching with `matchCondition` JsonLogic expressions, you can create targeted streaks like _"only Christmas-themed activities performed in December"_ or _"quizzes with difficulty >= 3"_.

## Streak Rule

A **Streak Rule** defines _the rules of the game_: how often the user must act, for how long, what goals to track, and what happens when they miss a period. Every rule references a Streak Configuration via `streakConfigurationId`.

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `streakRuleId` | nanoid | Unique identifier |
| `streakConfigurationId` | string | References the Streak Configuration |
| `name` | string | Human-readable name |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Lifecycle state |
| `usersMatchCondition` | JsonLogic | Which users this rule applies to (evaluated against user profile + tags) |

### Cadence and Metric

These two fields define _how_ the streak counts progress:

| Field | Type | Default | Description |
|-------|------|---------|-------------|
| `cadence` | `DAY` \| `WEEK` | required | How often the user must be active to maintain the streak |
| `metric` | `DAYS` \| `WEEKS` | `DAYS` | What each increment of the counter represents |

**Cadence** determines the _frequency_ requirement:
- `DAY` = the user must act every calendar day to keep the streak alive.
- `WEEK` = the user must act at least once per ISO calendar week.

**Metric** determines _what gets counted_ in ITERATION and GOAL records:
- `DAYS` = each increment of `count` represents one active day.
- `WEEKS` = each increment of `count` represents one active week.

These are orthogonal dimensions. The most common combinations:

| Cadence | Metric | Meaning |
|---------|--------|---------|
| `DAY` | `DAYS` | User must act daily; counters track active days |
| `WEEK` | `DAYS` (default) | User must act weekly; counters track active days within the streak |
| `WEEK` | `WEEKS` | User must act weekly; counters track consecutive active weeks |

> **Constraint**: `DAY` cadence can only have `DAYS` metric (or undefined). `WEEKS` metric only makes sense with `WEEK` cadence.

### Timeframe

| Field | Type | Description |
|-------|------|-------------|
| `timeframeType` | `PERMANENT` \| `RANGE` | Whether the rule runs indefinitely or has a fixed end date |
| `timeframeStartsAt` | ISO datetime | When the rule begins |
| `timeframeEndsAt` | ISO datetime? | When the rule ends (required for `RANGE`) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Whether to use a fixed timezone or each user's own timezone |
| `timeframeTimezone` | timezone? | The fixed timezone (required when `timeframeTimezoneType` is `FIXED`) |

The timezone setting is critical for determining period boundaries. With `USER` timezone, a user in Tokyo and a user in London will have different "day" boundaries, ensuring fairness regardless of location.

### Goal Targets

| Field | Type | Description |
|-------|------|-------------|
| `goalTargets` | number[]? | Milestones the user can reach (e.g., `[7, 30, 100, 365]`) |

Goal targets define milestone thresholds. When a user's cumulative count reaches a target, the corresponding GOAL record is marked `COMPLETED`. Multiple targets create a tiered system: reach 7 days in a row, then 30, then 100, etc. Once all targets for a cycle are completed, a new goal cycle begins with `goalId` incremented.

### Perfect Period Tracking

| Field | Type | Description |
|-------|------|-------------|
| `perfectWeekEnabled` | boolean | Track whether the user was active every day of a week |
| `perfectMonthEnabled` | boolean | Track whether the user was active every day/week of a month |
| `perfectYearEnabled` | boolean | Track whether the user was active every day/week of a year |

These booleans enable additional tracking on calendar records (WEEK, MONTH, YEAR). A "perfect week" means the user was active on all 7 days (for DAY cadence) or didn't miss any required period.

### Freeze Settings

| Field | Type | Description |
|-------|------|-------------|
| `freezeEnabled` | boolean | Whether users can spend virtual currency to preserve a streak |
| `freezeVirtualCurrencyId` | string? | Which virtual currency to deduct (required when freeze is enabled) |
| `freezeCostExpression` | JsonLogic? | Expression to calculate freeze cost (receives `{ user, streak }` context) |

When a streak is about to break (the maintenance scheduler detects a missed period), the system can automatically deduct virtual currency to "freeze" the streak instead of breaking it. The cost is dynamic via JsonLogic — for example, the cost could increase with longer streaks.

## Streak (Records)

A **Streak** is a DynamoDB record that tracks a specific counter for a specific user under a specific rule. The key insight is that **a single user action generates multiple streak records simultaneously** — each tracking a different dimension of the same streak.

### Record Fields

| Field | Type | Description |
|-------|------|-------------|
| `streakId` | nanoid | Unique record identifier (auto-generated on first write) |
| `userId` | string | The user this record belongs to |
| `streakRuleId` | string | The rule this record belongs to |
| `periodType` | enum | The time window or tracking dimension (see below) |
| `periodId` | string? | Calendar period identifier (e.g., `2025-09-02`, `2025-W37`) |
| `cadence` | `DAY` \| `WEEK` | Inherited from the rule |
| `metric` | `DAYS` \| `WEEKS` | What `count` represents |
| `count` | number | Accumulated counter (atomically incremented) |
| `status` | `ACTIVE` \| `COMPLETED` \| `BROKEN` \| `ENDED` | Lifecycle state |
| `kind` | `REGULAR` \| `FREEZE` \| `ANY` | How this period was kept alive |
| `iterationId` | number? | Which consecutive run this belongs to (for ITERATION records) |
| `goalId` | number? | Which goal cycle this belongs to (for GOAL records) |
| `target` | number? | The milestone threshold (for GOAL records) |
| `timezone` | string | The effective timezone used for period calculation |

### Period Types

The `periodType` field is what makes streak records versatile. There are two categories:

#### Calendar Records (log/historical)

These record _what happened_ in a specific time window. They serve as a calendar view and historical log.

| periodType | periodId example | count | Description |
|------------|-----------------|-------|-------------|
| `DAY` | `2025-09-02` | Always 1 | Binary marker: the user was active on this day |
| `WEEK` | `2025-W37` | Days or weeks active | How many times the user was active this week |
| `MONTH` | `2025-09` | Days or weeks active | How many times the user was active this month |
| `YEAR` | `2025` | Days or weeks active | How many times the user was active this year |

Calendar records are **always written regardless of the `metric` setting**. They are what the frontend calendar view renders.

- A `DAY` record has `status: COMPLETED` and `count: 1` — it is a simple "this day happened" marker.
- `WEEK`, `MONTH`, `YEAR` records have `status: ACTIVE` and their `count` is atomically incremented each time the user acts within that period. They accumulate.

#### Counter Records (progress tracking)

These track cumulative progress and streaks. They are **conditionally written based on the rule's `metric` setting**.

| periodType | Uses | count | Description |
|------------|------|-------|-------------|
| `ITERATION` | `iterationId` | Consecutive days or weeks | Tracks a single unbroken streak run. When the streak breaks and restarts, `iterationId` increments. |
| `GOAL` | `goalId` + `target` | Progress toward target | Tracks progress toward a specific milestone. One record per target per goal cycle. |

- An **ITERATION** record answers: _"How long is the current unbroken streak?"_ When count reaches high values, the user has maintained a long streak. When the streak breaks (status changes to `BROKEN`), a new iteration begins with an incremented `iterationId`.

- A **GOAL** record answers: _"How close is the user to reaching X days/weeks?"_ For `goalTargets: [7, 30, 100]`, three GOAL records are maintained per goal cycle. When count reaches the target, `status` becomes `COMPLETED`. When all targets are completed, a new cycle starts with `goalId` incremented.

### Status Lifecycle

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

- **ACTIVE**: The record is being tracked and can be incremented.
- **COMPLETED**: The record reached its goal target (GOAL) or represents a completed calendar day (DAY). Cannot be further incremented.
- **BROKEN**: The user missed a required period and the streak was broken. Terminal state for ITERATION records.
- **ENDED**: The streak rule has ended (`state: ENDED`). Terminal state.

Only `ACTIVE` records can be updated — the system enforces this via DynamoDB conditions.

### Kind

| Kind | Description |
|------|-------------|
| `REGULAR` | The period was completed by real user activity |
| `FREEZE` | The period was preserved by spending virtual currency |
| `ANY` | Aggregate — used for ITERATION and GOAL records which don't distinguish between regular and frozen periods |

## How Records Are Written

When a user completes an action that matches a streak configuration, the system writes multiple DynamoDB records in a single transaction. The exact set depends on the cadence and metric.

### DAY Cadence

A single code path (`updateDayCadenceStreakCounters`) handles everything. On each qualifying action (max once per calendar day):

| Record | periodType | metric | Always written? |
|--------|-----------|--------|-----------------|
| Day entry | `DAY` | `DAYS` | Yes (calendar) |
| Week accumulator | `WEEK` | `DAYS` | Yes (calendar) |
| Month accumulator | `MONTH` | `DAYS` | Yes (calendar) |
| Year accumulator | `YEAR` | `DAYS` | Yes (calendar) |
| Iteration counter | `ITERATION` | `DAYS` | Yes |
| Goal counters | `GOAL` | `DAYS` | Yes (one per target) |

For DAY cadence, `metric` is always `DAYS` — there's no ambiguity.

### WEEK Cadence

Two sub-paths run independently with their own deduplication guards:

**`updateDayMetrics`** — runs per calendar day (first action of the day):

| Record | periodType | metric | Written when |
|--------|-----------|--------|--------------|
| Day entry | `DAY` | `DAYS` | Always (calendar) |
| Iteration counter | `ITERATION` | `DAYS` | Only if `rule.metric` is `DAYS` (default) |
| Goal counters | `GOAL` | `DAYS` | Only if `rule.metric` is `DAYS` (default) |

**`updateWeekMetrics`** — runs per calendar week (first action of the week):

| Record | periodType | metric | Written when |
|--------|-----------|--------|--------------|
| Week entry | `WEEK` | `WEEKS` | Always (calendar) |
| Month accumulator | `MONTH` | `WEEKS` | Always (calendar) |
| Year accumulator | `YEAR` | `WEEKS` | Always (calendar) |
| Iteration counter | `ITERATION` | `WEEKS` | Only if `rule.metric` is `WEEKS` |
| Goal counters | `GOAL` | `WEEKS` | Only if `rule.metric` is `WEEKS` |

This split ensures that ITERATION and GOAL records are written exactly once per the appropriate time granularity:
- With `metric: DAYS` (default): iteration counts active _days_, goals track _days_ of progress, and the day-level dedup guard ensures at most one increment per day.
- With `metric: WEEKS`: iteration counts active _weeks_, goals track _weeks_ of progress, and the week-level dedup guard ensures at most one increment per week.

### Deduplication

Each code path has a dedup guard that prevents double-counting:

- **Day dedup**: Before writing day metrics, the system queries for an existing `DAY` record with today's `periodId`. If found, the entire function returns early (no records written).
- **Week dedup**: Before writing week metrics, the system queries for an existing `WEEK` record with this week's `periodId`. If found, the entire function returns early.

Additionally, the `prepareStreakUpdate` function adds DynamoDB conditions to ensure records are only written/updated when `status` is `ACTIVE` (or the record doesn't exist yet).

## DynamoDB Access Patterns

### Partition Key

All streak records for a user share the same partition key:

```
pk = workspaceId#<workspaceId>#userId#<userId>
```

### Sort Key (sk)

The primary sort key encodes the full record identity:

```
periodType#DAY#periodId#2025-09-02#streakRuleId#ID1#cadence#DAY#metric#DAYS#kind#REGULAR
periodType#ITERATION#iterationId#000001#streakRuleId#ID1#cadence#WEEK#metric#DAYS#kind#ANY
periodType#GOAL#goalId#000001#target#000007#streakRuleId#ID1#cadence#DAY#metric#DAYS#kind#ANY
```

This structure enables efficient range queries by `periodType` and `periodId` — for example, fetching all DAY records between two dates.

### Secondary Sort Key (sk2)

A GSI (`bySk2`) reorders the sort key with `streakRuleId` first:

```
#streakRuleId#ID1periodType#DAY#periodId#2025-09-02#cadence#WEEK#metric#DAYS#kind#REGULAR
```

This enables efficient queries filtered by a specific streak rule — used internally by the counter update logic to check dedup guards and fetch the latest iteration/goal state.

## Streak Lifecycle Management

A scheduled maintenance process runs for each active streak to detect missed periods:

1. When a streak record is written, a **StreakSchedule** entry is created that fires after the current period ends.
2. The scheduler invokes `updateStreakStatus`, which:
   - Fetches the streak rule and user.
   - If the rule is `ENDED`, marks the streak as `ENDED`.
   - If the rule is `ACTIVE`, queries streak records in the expected time range.
   - If the user was active (records found for the expected period), the streak continues — a `FREEZE`-kind counter update is written to advance the streak.
   - If the user was _not_ active, the system checks whether the user can afford a **freeze** (virtual currency deduction). If yes, the streak is preserved. If not, the streak is marked as `BROKEN`.

## Multiple Streaks Per User

A user can have multiple active streaks simultaneously, each tracked independently:

- **Different rules**: A workspace might have a "Daily Activity Streak" (DAY cadence) and a "Weekly Quiz Streak" (WEEK cadence). Each generates its own set of records under a different `streakRuleId`.
- **Targeted streaks**: Using `TAG` match type on the configuration, you can create seasonal streaks like _"Christmas Activity Streak"_ that only counts activities tagged with a specific tag. The same user might have a general daily streak and a seasonal December streak running in parallel.
- **Different goal tiers**: A single rule with `goalTargets: [7, 30, 100, 365]` creates multiple GOAL records per cycle, but they all belong to the same rule.

## Example: Full Record Set

Consider a user on day 15 of a WEEK-cadence streak with `metric: DAYS` and `goalTargets: [7, 30]`:

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

In this example:
- The user is on iteration #2 (their first streak broke at some point, this is their second run).
- They are on goal cycle #3 (they completed two full cycles of all targets previously).
- The 7-day goal for this cycle is `COMPLETED`; the 30-day goal is in progress at count 15.
- Calendar records show 3 active days this week, 11 this month, 190 this year.
- The `WEEK`, `MONTH`, `YEAR` calendar records use `metric: WEEKS` because they are written by `updateWeekMetrics` (which always uses WEEKS metric for its calendar entries).

## List API

The list API (`GET /streaks`) supports querying by `periodType` with optional date ranges:

- **Calendar view**: `periodType=DAY&from=2025-09-01&to=2025-09-30` returns all daily markers for September.
- **Iteration history**: `periodType=ITERATION` returns all streak runs (each with their `iterationId` and `count`).
- **Goal progress**: `periodType=GOAL` returns all goal records across all cycles.

On the last page of results, the API also **synthesizes empty counters** for any active rules that have no streak records yet. This ensures the frontend always shows all active rules, even if the user hasn't started them.

Optional filters: `streakRuleId` (uses the `bySk2` GSI for efficient lookups), `iterationId`, `goalId`, `target`.

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **StreakConfiguration** | Defines _what events_ count (entity matching + JsonLogic conditions) |
| **StreakRule** | Defines _the game rules_ (cadence, metric, goals, freeze, timeframe) |
| **Streak** | Per-user DynamoDB records that track every dimension of progress |
| **Cadence** | How often the user must act (`DAY` = daily, `WEEK` = weekly) |
| **Metric** | What counters represent (`DAYS` = active days, `WEEKS` = active weeks) |
| **periodType** | The dimension being tracked (calendar: DAY/WEEK/MONTH/YEAR; progress: ITERATION/GOAL) |
| **Iteration** | A single unbroken streak run; increments when the streak breaks and restarts |
| **Goal** | A milestone target; cycles through `goalId` increments as targets are completed |
| **Kind** | Whether a period was kept by real activity (`REGULAR`) or virtual currency (`FREEZE`) |
| **Freeze** | Automatic virtual currency deduction to prevent streak breakage |

## Related Domains

- **Reward & Currency Domain**: the freeze mechanism deducts virtual currency to preserve streaks; reward rules can also trigger on streak-related events.
- **Mission Domain**: mission completion and activity events are common triggers for streak configurations.
- **Learning Content Domain**: learning path and quiz completions can feed streak counters through entity matching.
- **Leaderboard Domain**: streak-based engagement contributes to leaderboard scores indirectly through virtual currency accumulation.
- **Cross-Cutting Patterns**: JsonLogic expressions, entity matching (INSTANCE/ENTITY/TAG), timeframes, and state lifecycle patterns used throughout this domain.
