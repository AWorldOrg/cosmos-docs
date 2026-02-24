The mission system turns user actions into structured goals. It answers questions like _"Has this user completed 10 quizzes this week?"_ or _"Has the marketing team collectively finished 50 activities this month?"_

This section covers the full configuration model: entity hierarchies, matching logic, assignment modes, and lifecycle management. It is relevant for anyone configuring missions through the dashboard or integrating them via API. For a high-level overview of what missions do, see the Gamification Fundamentals. For shared patterns used across all domains (JsonLogic expressions, timeframes, entity matching), see Cross-Cutting Patterns.

The domain is built around four entities that form a clear hierarchy:

```
MissionConfiguration  (what counts and how to count it)
      │
      └──▶ MissionRule  (when, for whom, and how to assign)
                │
                └──▶ Mission  (per-user or per-group tracking instance)
                        │
                        └──▶ MissionLog  (immutable progress audit trail)
```

## Mission Configuration

A **Mission Configuration** defines _what user actions count_ toward a mission and _how progress is measured_. It is the template that specifies matching logic, increment rules, and completion targets.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `missionConfigurationId` | nanoid | Unique identifier |
| `name` | string | Human-readable reference (e.g., "Answer 10 Quizzes Correctly") |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Whether missions track one user or a group |
| `matchType` | `INSTANCE` \| `ENTITY` \| `TAG` | How to match incoming events |
| `matchEntity` | `Activity` \| `Quiz` \| `Tag` | Which entity type to watch |
| `matchEntityId` | string? | Specific entity or tag ID (required for `INSTANCE` and `TAG`) |
| `matchCondition` | JsonLogic | Additional matching logic evaluated at runtime |
| `incrementExpression` | JsonLogic | How much progress each matching event adds |
| `targetAmountExpression` | JsonLogic | The completion threshold |
| `origin` | `CATALOG` \| `CUSTOM` | Where this configuration was created |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (1–10) |

### Match Types

- **`INSTANCE`**: Matches a _specific_ entity. Example: completing activity `abc123`. Requires `matchEntityId`.
- **`ENTITY`**: Matches _any_ entity of that type. Example: completing any quiz.
- **`TAG`**: Matches any entity tagged with the given tag. Example: completing any activity tagged `sustainability`. Requires `matchEntityId` (the tag ID).

### Expressions

The three expression fields are what make mission configurations flexible:

**`matchCondition`** filters which events qualify. It receives `{ mission }` as context and must return a truthy value for the event to count. Example: only count quizzes with outcome `SUCCESS`.

**`incrementExpression`** defines how much progress each qualifying event adds. It receives `{ user, event }` and must return a number. A static value like `1` means "add 1 per event". A conditional expression can award different amounts based on context — for instance, awarding `2` for hard quizzes and `1` for easy ones.

**`targetAmountExpression`** defines when the mission is complete. It receives `{ user, mission }` and must return a number. A static `10` means "complete after 10 increments". A dynamic expression can set different targets per user — for instance, a higher target for premium users.

> **Constraint**: When a JsonLogic expression evaluates to `null`, empty string, or `NaN`, the system defaults to `1` for both increment and target calculations.

## Mission Rule

A **Mission Rule** defines _when and for whom_ missions are assigned. Every rule references one or more Mission Configurations (via a pool or matching condition) and controls how those configurations are instantiated as actual missions for users.

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `missionRuleId` | nanoid | Unique identifier |
| `name` | string | Human-readable name |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Must match the referenced configurations |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Lifecycle state |
| `assignmentMode` | `LAZY` \| `EVENT` \| `DISABLED` | How missions are assigned to users |
| `usersMatchCondition` | JsonLogic? | Which users this rule applies to (required for INDIVIDUAL) |
| `missionsMatchCondition` | JsonLogic | Filters which configurations to instantiate |
| `missionConfigurationsPool` | string[]? | Explicit list of configuration IDs to use (alternative to matching) |

### Assignment Modes

The assignment mode determines _how_ and _when_ missions are created for users:

**`LAZY`**: Missions are created on-demand when a user browses available missions. If the user matches the rule's conditions, the mission is generated in real time. Ideal for discovery-driven experiences where users choose which missions to pursue.

**`EVENT`**: Missions are assigned automatically when a matching event occurs — for example, assigning a follow-up mission when the user completes a Learning Path. This is real-time and reactive.

**`DISABLED`**: No assignments are made. Used for deactivating a rule without deleting it.

### Event Mode Fields

When `assignmentMode` is `EVENT`, four additional fields become required:

| Field | Type | Description |
|-------|------|-------------|
| `eventMatchType` | `INSTANCE` \| `ENTITY` \| `TAG` | How to match the triggering event |
| `eventMatchEntity` | `Activity` \| `Quiz` \| `Tag` \| `User` | Which entity type triggers assignment |
| `eventMatchEntityId` | string | Specific entity or tag ID |
| `eventMatchCondition` | JsonLogic | Additional filtering on the event |

> **Constraint**: All four `eventMatch*` fields are required when `assignmentMode` is `EVENT` and must be absent for other modes.

### User and Mission Targeting

**`usersMatchCondition`** determines which users are eligible for this rule. It receives `{ user, activeMissions }` as context — where `activeMissions` is the list of missions already assigned to the user. This allows rules like "only assign if the user doesn't already have 3 active missions".

> **Constraint**: `usersMatchCondition` is required for `INDIVIDUAL` rules and must be absent for `GROUP` rules (the entire group is eligible by definition).

**`missionsMatchCondition`** filters which Mission Configurations should be instantiated. It receives `{ user, activeMissions, mission }` where `mission` is a candidate configuration. This allows rules like "only assign configurations tagged with the user's department".

**`missionConfigurationsPool`** is an alternative to `missionsMatchCondition` — an explicit list of configuration IDs. When present, only these configurations are considered.

### Timeframe

| Field | Type | Description |
|-------|------|-------------|
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Whether the rule runs indefinitely, once, or repeats |
| `timeframeStartsAt` | ISO datetime | When the rule begins |
| `timeframeEndsAt` | ISO datetime? | When the rule ends (required for `RANGE` and `RECURRING`) |
| `timeframeTimezoneType` | `FIXED` \| `USER` | Whether to use a fixed timezone or each user's own |
| `timeframeTimezone` | timezone? | The fixed timezone (required when `FIXED`) |
| `recurrence` | `DAILY` \| `WEEKLY` \| `MONTHLY` \| `CUSTOM`? | Reset cadence (required for `RECURRING`) |
| `scheduleCron` | cron? | Cron expression (required when recurrence is `CUSTOM`) |

For a full explanation of timeframe, recurrence, and timezone handling, see the Cross-Cutting Patterns document.

### Group Targeting

| Field | Type | Description |
|-------|------|-------------|
| `groupTagId` | string? | The tag that identifies the group (required for `GROUP` rules) |

> **Constraint**: `GROUP` rules require `groupTagId`. `INDIVIDUAL` rules must not have it.

## Mission (Assignment)

A **Mission** is a tracking instance — the concrete assignment of a Mission Configuration to a specific user or group under a specific rule. It holds the current progress and the frozen target.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `missionId` | nanoid | Unique identifier |
| `missionConfigurationId` | nanoid | The configuration this mission is based on |
| `missionRuleId` | nanoid? | The rule that triggered this assignment |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Inherited from configuration |
| `userId` | nanoid? | The user this mission belongs to (INDIVIDUAL only) |
| `groupTagId` | string? | The group this mission belongs to (GROUP only) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Lifecycle state |
| `isCompleted` | boolean? | Whether the target has been reached |
| `completedAt` | ISO datetime? | When the mission was completed |
| `currentAmount` | number | Accumulated progress |
| `targetAmount` | number | Frozen completion threshold |
| `periodId` | string | Deduplication key for recurring missions |

The mission also carries copies of matching and expression fields from the configuration (`matchType`, `matchEntity`, `matchEntityId`, `matchCondition`, `incrementExpression`, `targetAmountExpression`) so that progress tracking does not depend on the configuration remaining unchanged.

### Mission Types

**INDIVIDUAL missions** are assigned to a single user. Each user gets their own mission instance with independent progress tracking. When `currentAmount >= targetAmount`, the mission is marked as completed and stops accepting further increments.

**GROUP missions** are assigned to a group identified by a tag. All users in the group contribute to the same `currentAmount`. Unlike individual missions, group missions **continue counting after reaching the target** — they track cumulative group progress without capping.

> **Constraint**: INDIVIDUAL missions require `userId` and forbid `groupTagId`. GROUP missions require `groupTagId` and forbid `userId`.

### Period Identification

The `periodId` field serves as a deduplication key that prevents the same rule from assigning duplicate missions in the same time period:

| Timeframe | periodId Format | Example |
|-----------|----------------|---------|
| `PERMANENT` | `"PERMANENT"` | `PERMANENT` |
| `RANGE` | Rule's start time in UTC | `2025-01-01T00:00:00` |
| `RECURRING` / `DAILY` | `YYYY-MM-DD` | `2025-09-15` |
| `RECURRING` / `WEEKLY` | `YYYY-Www` | `2025-W38` |
| `RECURRING` / `MONTHLY` | `YYYY-MM` | `2025-09` |
| `RECURRING` / `CUSTOM` | Cron last-fire time in UTC | `2025-09-15T06:00:00` |

A **MissionRuleEvaluation** record is created each time a rule is evaluated for a user/group in a given period, preventing duplicate assignments.

### Status Lifecycle

```
    rule assigns mission
           │
    ┌──────▼──────┐
    │   PENDING    │ ◀── mission starts in the future
    └──────┬──────┘
           │  startsAt reached
           ▼
    ┌─────────────┐     currentAmount >= targetAmount
    │   ACTIVE    │ ──────────────────────────────────▶ isCompleted = true
    └──────┬──────┘     (INDIVIDUAL only; GROUP keeps counting)
           │  endsAt reached
           ▼
    ┌─────────────┐
    │   ENDED     │ ◀── timeframe expired
    └─────────────┘
```

- **PENDING**: The mission exists but its timeframe hasn't started. `targetAmount` is not yet calculated.
- **ACTIVE**: The mission is accepting progress. On transition to ACTIVE, the `targetAmount` is calculated from `targetAmountExpression` and frozen — subsequent changes to the expression or user context do not affect it.
- **ENDED**: The timeframe has expired. Terminal state.

## Mission Log

A **Mission Log** is an immutable record created every time a mission's progress is updated. It provides a complete audit trail of which user contributed what amount and when.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `missionLogId` | nanoid | Unique identifier |
| `missionId` | nanoid | The mission that was updated |
| `missionConfigurationId` | nanoid | The configuration reference |
| `missionType` | `INDIVIDUAL` \| `GROUP` | Mission type |
| `userId` | nanoid | The user who triggered the progress |
| `groupTagId` | nanoid? | For group missions |
| `amount` | number | The increment applied (default: 1) |
| `additionalData` | record? | Extra context from the source event |

For group missions, the `userId` records _which_ user in the group contributed, while the increment applies to the shared `currentAmount`.

## How Missions Are Assigned

When a user action occurs (completing an activity, passing a quiz, etc.), the system follows different paths depending on the assignment mode:

### EVENT Mode Flow

1. The source system (Activity, Quiz, etc.) publishes an event.
2. The mission engine queries for all `ACTIVE` rules with `assignmentMode: EVENT` that match the event's entity type and ID.
3. For each matching rule:
   - The `eventMatchCondition` is evaluated against the event data.
   - The `usersMatchCondition` is evaluated against the user (for INDIVIDUAL) or skipped (for GROUP).
   - The `missionsMatchCondition` (or `missionConfigurationsPool`) determines which configurations to instantiate.
   - A `MissionRuleEvaluation` check prevents duplicate assignments in the same period.
4. New Mission assignments are created in batch.

### LAZY Mode Flow

1. A user browses available missions (e.g., opens the missions screen).
2. The system queries for all `ACTIVE` rules with `assignmentMode: LAZY`.
3. For each rule, the same evaluation chain runs: user eligibility → configuration matching → deduplication check.
4. Eligible missions are created on-the-fly and returned to the user.

### Source Event Remapping

Source events are remapped to match entity types before evaluation:

| Source Event | Maps To |
|-------------|---------|
| `ActivityLog` | `Activity` |
| `QuizLog` | `Quiz` |
| Others | Pass through |

## How Progress Is Tracked

When a user performs an action that might count toward a mission:

1. The system queries for all `ACTIVE`, non-completed missions that match the event (by `matchType`, `matchEntity`, `matchEntityId`).
2. For each matching mission, the `matchCondition` is evaluated against the event context.
3. If the condition passes, the `incrementExpression` is evaluated to determine how much to add.
4. The mission's `currentAmount` is atomically incremented.
5. An immutable `MissionLog` entry is created.
6. For INDIVIDUAL missions: if `currentAmount >= targetAmount`, the mission is marked as completed (`isCompleted: true`, `completedAt` set).
7. For GROUP missions: the counter continues regardless of whether the target was reached.

### Idempotency

The counter update is idempotent — if the same event is processed twice (due to retries or at-least-once delivery), the mission's `currentAmount` is only incremented once. This is enforced via an idempotency key based on the event ID.

Mission completion uses a conditional database update that only sets `isCompleted: true` if it was previously `false`, preventing double-completion.

## Example: Full Configuration

Consider a company that wants to create a weekly quiz challenge: _"Complete 5 quizzes with a passing score each week."_

### Step 1: Mission Configuration

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

This says: _count any quiz completion where the outcome is SUCCESS, add 1 per event, complete at 5._

### Step 2: Mission Rule

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

This says: _every week, make this mission available to all users (LAZY — they see it when they browse missions). Use each user's local timezone for week boundaries._

### Step 3: What Happens at Runtime

1. **Monday**: User opens the missions screen. The LAZY rule is evaluated. A new Mission is created:
   - `periodId: "2025-W38"`, `state: "ACTIVE"`, `currentAmount: 0`, `targetAmount: 5`
2. **Tuesday**: User completes a quiz with outcome SUCCESS. The `matchCondition` passes. `incrementExpression` returns 1. Mission becomes `currentAmount: 1`.
3. **Wednesday**: User completes a quiz but fails. The `matchCondition` evaluates to false (outcome is not SUCCESS). No increment.
4. **Friday**: User completes 4 more passing quizzes. Mission reaches `currentAmount: 5`, `isCompleted: true`.
5. **Next Monday**: A new period begins (`2025-W39`). The LAZY rule creates a fresh mission with `currentAmount: 0`.

### Alternative: Event-Based Team Mission

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

This says: _when any user completes the onboarding activity, assign a group mission to the engineering department. The mission tracks collective progress from September 1–30, Rome time._

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **MissionConfiguration** | Defines _what events count_ and _how to measure progress_ (matching + expressions) |
| **MissionRule** | Defines _when, for whom, and how_ missions are assigned (timeframe + targeting + mode) |
| **Mission** | Per-user or per-group tracking instance with frozen target and live progress |
| **MissionLog** | Immutable audit trail of every progress event |
| **assignmentMode** | How missions are created: `LAZY` (on-demand), `EVENT` (reactive), `DISABLED` (off) |
| **missionType** | `INDIVIDUAL` (one user, stops at target) or `GROUP` (shared counter, keeps going) |
| **matchType** | How events are matched: `INSTANCE` (specific), `ENTITY` (any of type), `TAG` (by tag) |
| **periodId** | Deduplication key ensuring one mission per rule per time period |
| **targetAmount** | Frozen when mission becomes ACTIVE — immune to later configuration changes |
| **MissionRuleEvaluation** | Tracks which rule+period combinations have been evaluated, preventing duplicates |

## Related Domains

- **Reward and Currency Domain**: mission completion events can trigger reward rules, automatically awarding virtual currency.
- **Leaderboard Domain**: leaderboards can rank users by mission-related metrics.
- **Streak Domain**: streaks can track activity completions that also feed into missions.
- **Cross-Cutting Patterns**: JsonLogic expressions, entity matching, timeframe and scheduling, and state lifecycle patterns used throughout this domain.
