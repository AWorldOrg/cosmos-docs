The learning content system manages structured educational experiences. It answers questions like _"What learning paths are assigned to this user?"_, _"How far has the user progressed?"_, and _"Should the next path unlock now that the previous one is complete?"_

This section covers the full configuration model: content hierarchies, rule-based assignment and unlocking, visibility management, and progress tracking. It is relevant for anyone designing learning experiences or integrating them via API. For a high-level overview, see the Gamification Fundamentals. For shared patterns (JsonLogic expressions, timeframes, entity matching), see Cross-Cutting Patterns.

The domain is built around a hierarchy of content containers, a rule system for assignment and access control, and a progress tracking layer:

```
LearningPathRule  (when, for whom, and how to assign or unlock)
      │
      └──▶ LearningPathAssignment  (per-user assignment with visibility)
                │
                └──▶ LearningPath  (content container)
                        │
                        ├──▶ Quiz
                        ├──▶ Slide
                        ├──▶ Activity
                        └──▶ LearningGroup  (nested container)
                                │
                                ├──▶ Quiz
                                ├──▶ Slide
                                └──▶ Activity
```

Progress is tracked at each level:

```
LearningPathLog   (per-user progress on a learning path)
LearningGroupLog  (per-user progress on a learning group)
```

## Learning Path

A **Learning Path** is the top-level content container — an ordered sequence of items that a user works through. Items can be quizzes, slides, activities, or nested learning groups.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningPathId` | nanoid | Unique identifier |
| `title` | string | Display title |
| `description` | string? | Optional description |
| `image` | URL? | Optional thumbnail image |
| `estimatedDuration` | number | Estimated time to complete |
| `items` | ItemReference[] | Ordered list of content items |
| `completionRule` | JsonLogic? | When is the path complete? (default: all items complete) |
| `outcomeRule` | JsonLogic? | What is the outcome? (default: FAIL if any item failed) |
| `startRule` | JsonLogic? | Has the path been started? (default: any item has progress) |
| `origin` | `CATALOG` \| `AI` \| `CUSTOM` | Where this path was created |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (1–10) |

### Polymorphic Items

The `items` array contains references to content of different types. Each reference has three fields:

| Field | Type | Description |
|-------|------|-------------|
| `itemId` | string | ID of the referenced content entity |
| `itemType` | enum | `activity` \| `game` \| `quiz` \| `story` \| `slide` \| `learningGroup` |
| `languages` | lang[]? | If set, the item only appears in these language variants |

The `itemType` field is the discriminant — it tells the system which entity type to look up. A learning path can mix any combination of item types.

**Language-specific items**: When `languages` is set (e.g., `["it", "de"]`), the item only appears when the user views the path in one of those languages. When `languages` is undefined or empty, the item appears in all languages.

### Completion, Outcome, and Start Rules

These three JsonLogic expressions control how aggregate progress is calculated. They all receive the same context: `{ items: ItemLogStatus[] }`, where each item has `progress` and `outcome` fields.

**Completion rule** — determines when the path is considered complete:
- Default: all items must have `progress === "COMPLETE"`.
- Custom example: path is complete when 80% of items are done.

**Outcome rule** — determines the overall result (only evaluated when complete):
- Default: `FAIL` if any item has `outcome === "FAIL"`, otherwise `SUCCESS`.
- Custom example: `SUCCESS` if at least 70% of quizzes passed.

**Start rule** — determines whether the user has begun the path:
- Default: the path is started if any item has non-null progress.

> **Note**: These rules are evaluated on every child item progress event. The evaluation is deterministic: given the current item statuses, the result is always the same.

### Backward Compatibility

Earlier versions of the platform used an `activities` field instead of `items`, and `activityId`/`activityType` instead of `itemId`/`itemType`. The system transparently normalizes old records at read time:
- `activityId` → `itemId`
- `activityType` → `itemType`
- `activities` array → `items` array

No migration is needed — the normalization happens in-memory.

## Learning Group

A **Learning Group** is a nested container within a learning path. It groups related items together — for example, a narrative sequence of slides followed by a quiz.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningGroupId` | nanoid | Unique identifier |
| `type` | `story` \| `test` \| `custom` | The semantic type of this group (default: `custom`) |
| `title` | string | Display title |
| `description` | string? | Optional description |
| `image` | URL? | Optional image |
| `estimatedDuration` | number? | Optional time estimate |
| `items` | ItemReference[] | Ordered list of content items |
| `source` | string? | Semantic relationship to another entity |
| `parentId` | string? | Parent entity ID (for cascade propagation) |
| `parentType` | `learningPath` \| `learningGroup`? | Parent entity type |
| `completionRule` | JsonLogic? | Same pattern as LearningPath |
| `outcomeRule` | JsonLogic? | Same pattern as LearningPath |
| `startRule` | JsonLogic? | Same pattern as LearningPath |
| `origin` | `CATALOG` \| `AI` \| `CUSTOM`? | Creation source |
| `defaultLang` | lang | Default language code |
| `langs` | lang[] | Supported languages (1–10) |

### Group Types

The `type` field gives semantic meaning to the group:

**`story`** — A narrative sequence. Typically contains slides and activities, organized as chapters or episodes of a story. This replaces the legacy standalone `Story` entity.

**`test`** — An assessment group. Typically contains quizzes. Often linked to a story group via the `source` field, indicating which story content this test assesses.

**`custom`** — A generic grouping with no specific semantic meaning. Default type. Used for arbitrary organization of items.

### Source Relationships

The `source` field creates semantic links between groups using a combined key format: `"entityType#entityId"`.

Common pattern: a test group references the story group it assesses:

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

### Parent Reference

The `parentId` and `parentType` fields track the group's position in the hierarchy. When a child item's progress changes, the event includes the parent reference so the progress handler knows which learning path or group to update upstream.

## Learning Path Rule

A **Learning Path Rule** controls how learning paths are assigned to users and how access is managed. There are two distinct rule types.

### Rule Types

**`ASSIGN`** — Creates new learning path assignments. An ASSIGN rule selects which users to target, which paths to assign, and what initial visibility each assignment should have (LOCKED or UNLOCKED).

**`UNLOCK`** — Updates the visibility of existing assignments from LOCKED to UNLOCKED. An UNLOCK rule watches for a specific event (typically a learning path completion) and unlocks the next path in the sequence.

### Core Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningPathRuleId` | nanoid | Unique identifier |
| `ruleType` | `ASSIGN` \| `UNLOCK` | What this rule does |
| `name` | string | Human-readable name |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Lifecycle state |
| `assignmentMode` | `LAZY` \| `EVENT` \| `DISABLED` | How assignments are triggered |
| `usersMatchCondition` | JsonLogic? | Which users are eligible |

### ASSIGN Rule Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningPathsPool` | nanoid[]? | Explicit list of learning path IDs to assign |
| `learningPathsMatchCondition` | JsonLogic? | Dynamic filter for selecting paths |
| `initialVisibilityCondition` | JsonLogic? | Determines LOCKED or UNLOCKED per path |

> **Constraint**: ASSIGN rules require either `learningPathsPool` (with at least one entry) or `learningPathsMatchCondition`.

### UNLOCK Rule Fields

| Field | Type | Description |
|-------|------|-------------|
| `unlockLearningPathId` | nanoid? | Which learning path to unlock |

> **Constraint**: UNLOCK rules require `unlockLearningPathId` and must use `assignmentMode: "EVENT"`.

### Assignment Modes

**`LAZY`**: Assignments are created on-demand when the user browses available paths. Only valid for ASSIGN rules.

**`EVENT`**: Assignments are created (or unlocked) when a matching event occurs. Required for UNLOCK rules. Valid for both ASSIGN and UNLOCK.

**`DISABLED`**: Rule is inactive.

### Event Matching

When `assignmentMode` is `EVENT`, these fields become required:

| Field | Type | Description |
|-------|------|-------------|
| `eventMatchType` | `INSTANCE` \| `ENTITY` \| `TAG` | How to match events |
| `eventMatchEntity` | `LearningPathLog` \| `User` \| `Tag` | Which entity triggers the rule |
| `eventMatchEntityId` | string | Specific entity or tag ID |
| `eventMatchCondition` | JsonLogic | Additional event filtering |

Common event triggers:
- **`LearningPathLog`** with `INSTANCE`: triggers when a specific learning path's progress changes — ideal for UNLOCK rules that fire on completion.
- **`User`** with `ENTITY`: triggers on any user event — useful for ASSIGN rules on user creation.
- **`Tag`** with `TAG`: triggers when a tag is assigned to a user — useful for ASSIGN rules that target users with specific tags.

### Timeframe

Same pattern as all rule entities: `timeframeType` (PERMANENT/RANGE/RECURRING), `timeframeStartsAt`, `timeframeEndsAt`, `timeframeTimezoneType` (FIXED/USER), `recurrence` (DAILY/WEEKLY/MONTHLY/CUSTOM), `scheduleCron`. See the Cross-Cutting Patterns document.

### User and Path Targeting

**`usersMatchCondition`** receives `{ user, activeAssignments }` — where `activeAssignments` is the list of paths already assigned to the user. This allows rules like "only assign if the user has fewer than 5 active paths".

**`learningPathsMatchCondition`** receives `{ user, learningPath }` and returns whether to include this path.

### Initial Visibility Condition

The `initialVisibilityCondition` is a JsonLogic expression evaluated once per path during ASSIGN rule execution. It receives `{ learningPath, index, user }` and must return `"LOCKED"` or `"UNLOCKED"`.

If not specified, all paths start as `UNLOCKED`.

Examples:

```json
// First path unlocked, rest locked (sequential unlock pattern)
{
  "if": [
    { "===": [{ "var": "index" }, 0] },
    "UNLOCKED",
    "LOCKED"
  ]
}
```

```json
// Unlock only for premium users
{
  "if": [
    { "===": [{ "var": "user.plan" }, "premium"] },
    "UNLOCKED",
    "LOCKED"
  ]
}
```

## Learning Path Assignment

A **Learning Path Assignment** is the per-user record that connects a user to a learning path under a specific rule. It tracks visibility (LOCKED/UNLOCKED) and temporal state (PENDING/ACTIVE/ENDED).

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningPathAssignmentId` | nanoid | Unique identifier |
| `learningPathId` | nanoid | Which path is assigned |
| `userId` | nanoid | Who it is assigned to |
| `learningPathRuleId` | nanoid? | Which rule created this assignment |
| `periodId` | string | Deduplication key (same format as mission `periodId`) |
| `timeframeType` | `PERMANENT` \| `RANGE` \| `RECURRING` | Temporal scope |
| `startsAt` | ISO datetime | When this assignment becomes active |
| `endsAt` | ISO datetime? | When it expires (required for RANGE/RECURRING) |
| `state` | `PENDING` \| `ACTIVE` \| `ENDED` | Time-based lifecycle |
| `visibility` | `LOCKED` \| `UNLOCKED` | Access control |
| `unlockedAt` | ISO datetime? | When the path was unlocked |
| `unlockedByRuleId` | nanoid? | Which UNLOCK rule triggered the unlock |
| `groupId` | string? | For dashboard organization |

### Visibility vs. State

These are independent dimensions:

- **State** is time-based and automatic: PENDING → ACTIVE → ENDED.
- **Visibility** is rule-based: starts as LOCKED or UNLOCKED (from ASSIGN rule), can be changed to UNLOCKED by an UNLOCK rule.

A user can only access a learning path when the assignment is both `ACTIVE` and `UNLOCKED`.

## Learning Path Log

A **Learning Path Log** tracks a user's progress through a specific learning path. There is one record per (learningPathId, userId, context) combination — it is updated in place, not appended.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningPathId` | nanoid | Which path |
| `userId` | nanoid | Which user |
| `context` | string | Named context (default: `"default"`) — allows multiple attempts |
| `lang` | lang | Language the user is working in |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE` | Overall progress |
| `outcome` | `SUCCESS` \| `FAIL`? | Only set when progress is `COMPLETE` |
| `items` | ItemLogStatus[]? | Progress of each child item |
| `currentItemId` | string? | ID of the item the user is currently on |
| `currentItemType` | itemType? | Type of the current item |
| `startedAt` | ISO datetime? | When the user first started |
| `completedAt` | ISO datetime? | When the user completed the path |

Each entry in the `items` array has:

| Field | Type | Description |
|-------|------|-------------|
| `itemId` | string | Item reference |
| `itemType` | itemType | Item type |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE`? | Item's progress |
| `outcome` | `SUCCESS` \| `FAIL`? | Item's outcome |

> **Constraint**: Progress can only advance: null → START → IN_PROGRESS → COMPLETE. It never goes backward.

### History

The log maintains a full version history. Each update creates a new versioned record in the history table, while the main table always holds the current state. This provides both fast current-state lookups and a complete audit trail.

## Learning Group Log

A **Learning Group Log** follows the same pattern as the Learning Path Log but tracks progress within a learning group.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `learningGroupId` | nanoid | Which group |
| `userId` | nanoid | Which user |
| `context` | string | Named context (default: `"default"`) |
| `lang` | lang | Language |
| `progress` | `START` \| `IN_PROGRESS` \| `COMPLETE` | Overall progress |
| `outcome` | `SUCCESS` \| `FAIL`? | Only when complete |
| `items` | ItemLogStatus[]? | Per-item progress |
| `parentId` | string? | Parent learning path or group |
| `parentType` | `learningPath` \| `learningGroup`? | Parent entity type |
| `currentItemId` | string? | Current item |
| `startedAt` | ISO datetime? | When started |
| `completedAt` | ISO datetime? | When completed |

## How Progress Cascades

When a user completes an item (e.g., finishes a quiz inside a learning group), progress cascades up the hierarchy:

1. The child item (quiz, slide, etc.) logs its completion.
2. An event is published with `parentId` and `parentType`.
3. The progress handler for the parent entity receives the event.
4. The handler updates the triggering item's status in the parent's `items` array.
5. The completion, outcome, and start rules are evaluated against the updated items.
6. The parent log is updated accordingly.
7. If the parent itself is now complete, this triggers another event up the chain.

```
Quiz completed
  → event: { parentId: "lg_1", parentType: "learningGroup" }
    → LearningGroup log updated
      → event: { parentId: "lp_1", parentType: "learningPath" }
        → LearningPath log updated
          → event: LearningPathLog progress = COMPLETE
            → UNLOCK rules may fire
```

### Current Item Determination

After each update, the system determines which item the user should work on next:
1. Find the first item with `progress === "START"` (in progress).
2. If none, find the first item with `progress === null` (not started).
3. If all items are complete, `currentItemId` is null.

## How Assignment and Unlock Work Together

The ASSIGN and UNLOCK rule types combine to create sequential learning experiences:

### Step 1: ASSIGN Rule Creates Assignments

An ASSIGN rule with `initialVisibilityCondition` creates assignments where the first path is UNLOCKED and the rest are LOCKED:

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

Result:
- `intro_path` → UNLOCKED (user can start)
- `intermediate_path` → LOCKED (visible but not accessible)
- `advanced_path` → LOCKED

### Step 2: UNLOCK Rule Watches for Completion

An UNLOCK rule watches for the completion of the intro path:

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

### Step 3: Completion Triggers Unlock

When the user completes `intro_path`:
1. The LearningPathLog progress becomes `COMPLETE`.
2. The event matches the UNLOCK rule.
3. The system finds the existing LOCKED assignment for `intermediate_path`.
4. The assignment is updated: `visibility: "UNLOCKED"`, `unlockedAt` set, `unlockedByRuleId` set.
5. The user can now access `intermediate_path`.

A second UNLOCK rule would handle unlocking `advanced_path` when `intermediate_path` completes.

## Deduplication

Assignment rules track which (rule, period, user) combinations have already been evaluated, using a **LearningPathRuleEvaluation** record. This prevents duplicate assignments when:
- A LAZY rule is evaluated multiple times for the same user.
- An EVENT rule fires on multiple events in the same period.
- A RECURRING rule resets — each new period gets its own evaluation check.

The `periodId` follows the same format as in the mission domain: `"PERMANENT"` for permanent rules, `"YYYY-MM-DD"` for daily recurring, `"YYYY-Www"` for weekly, etc.

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **LearningPath** | Top-level content container with an ordered sequence of polymorphic items |
| **LearningGroup** | Nested container with semantic types: `story`, `test`, `custom` |
| **LearningPathRule** | Controls assignment (`ASSIGN`) and access (`UNLOCK`) to learning paths |
| **LearningPathAssignment** | Per-user record with `visibility` (LOCKED/UNLOCKED) and `state` (PENDING/ACTIVE/ENDED) |
| **LearningPathLog** | Per-user progress record with per-item tracking and versioned history |
| **items** | Polymorphic array of references (`itemId`, `itemType`, `languages`) |
| **completionRule / outcomeRule / startRule** | JsonLogic expressions that compute aggregate progress from child item statuses |
| **initialVisibilityCondition** | JsonLogic that determines LOCKED or UNLOCKED at assignment time |
| **source** | Semantic link between learning groups (e.g., test → story relationship) |
| **Progress cascade** | Child item completion propagates up to parent group and path automatically |

## Related Domains

- **Reward and Currency Domain**: learning path and learning group completion events can trigger reward rules.
- **Mission Domain**: mission rules can use EVENT mode to assign missions when a learning path is completed.
- **Streak Domain**: learning activity completions feed into streak tracking.
- **Cross-Cutting Patterns**: JsonLogic expressions, entity matching, timeframe and scheduling, and state lifecycle patterns used throughout this domain.
