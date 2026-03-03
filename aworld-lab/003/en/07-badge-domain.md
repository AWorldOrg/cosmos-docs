The badge system awards visual recognitions to users when they reach specific milestones. It answers questions like _"Has this user completed the onboarding learning path and earned the Welcome badge?"_ or _"How many times has this user been awarded the Top Performer badge?"_

> This section covers the full badge model: configuration lifecycle, progress source linking, reward rule integration, and the user-facing badge record. It is relevant for anyone configuring badges through the dashboard or integrating them via API. For a high-level overview, see the Gamification Fundamentals. For the reward rule integration (how badges are awarded), see the Reward and Currency Domain.

The domain is built around two entities:

```
BadgeConfiguration  (the template: what the badge is and what drives its assignment)
      │
      └──▶ Badge  (per-user record: earned instances with assignment history)
                │
                └──▶ BadgeLog  (immutable record of each individual assignment)
```

## Badge Configuration

A **Badge Configuration** defines _what the badge is_, _how it looks_, and _what user achievement triggers its assignment_. It is the template that administrators create and publish before badges can be awarded.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `badgeConfigurationId` | nanoid | Unique identifier |
| `name` | string | Human-readable reference name (e.g., "Learning Path Completer") |
| `image` | URL | Badge image asset — **required** |
| `origin` | `CATALOG` \| `CUSTOM` | Whether this badge comes from the AWorld catalog or was created by the client |
| `catalogBadgeConfigurationId` | nanoid? | References the catalog source when `origin` is `CATALOG` |
| `syncWithCatalog` | boolean? | When true, the badge automatically updates when the catalog source changes |
| `progressSourceEntityType` | `MissionConfiguration` \| `LearningPath` | The entity type whose completion drives badge assignment |
| `progressSourceEntityId` | nanoid | The specific Mission Configuration or Learning Path that triggers assignment |
| `defaultLang` | lang | Default language code for translations |
| `langs` | lang[] | All supported language codes (1–10) |
| `accountId` | string | Account this badge belongs to |
| `workspaceId` | string | Workspace this badge belongs to |
| `createdAt` | ISO datetime | Creation timestamp |
| `updatedAt` | ISO datetime | Last update timestamp |

### Translations

Each Badge Configuration supports multilingual display through a `translations` array. Each translation contains:

| Field | Type | Description |
|-------|------|-------------|
| `lang` | lang | Language code (e.g., `en`, `it`, `ar`) |
| `label` | string | Display name of the badge in this language |
| `description` | string | Explanation of how to earn the badge |

### Tags

Badge Configurations support tag assignments, enabling categorization and targeting:

| Field | Type | Description |
|-------|------|-------------|
| `tagId` | nanoid | The tag assigned to this configuration |
| `priority` | number | Display order when multiple tags are assigned |

Tags on badge configurations allow filtering and grouping in the dashboard, as well as scoping reward rules to specific badge categories.

### Lifecycle

Badge Configurations follow a publish/archive lifecycle:

```
    DRAFT ──▶ PUBLISHED ──▶ ARCHIVED
                  │
                  └──▶ DRAFT (unarchive)
```

- **DRAFT**: The configuration exists but is not yet active. Badges cannot be awarded in this state.
- **PUBLISHED**: The configuration is active. Reward rules referencing this badge can trigger assignments.
- **ARCHIVED**: The configuration is inactive. No new assignments occur. Can be unarchived to return to PUBLISHED.

### Progress Source

The `progressSourceEntityType` and `progressSourceEntityId` fields define _what the user must accomplish_ to earn the badge:

- **`MissionConfiguration`**: the badge is linked to a specific mission template. When the reward rule fires upon mission completion, the badge is assigned.
- **`LearningPath`**: the badge is linked to a specific learning path. Completion of the learning path triggers assignment via a reward rule.

This field is informational for the frontend — it tells the app which entity to display as the badge's progress source, enabling progress bars and completion status display.

## How Badge Assignment Works

Badges are not assigned directly — they are awarded through the **Reward Rule** system. The connection is:

```
RewardRule  (rewardType: BADGE, badgeConfigurationId: ...)
      │
      ├── matchEntity: Mission | LearningPath | Activity | ...
      ├── matchCondition: { isCompleted: true }  (only on completion)
      └──▶ BadgeConfiguration assigned to user → Badge record created
```

The key constraint: **badges are awarded only when the triggering entity reaches completion**, not on partial progress. A reward rule for badge assignment must include an `isCompleted` check in its `matchCondition` to prevent early triggering.

See the [Reward and Currency Domain](03-reward-and-currency-domain.md) for the full reward rule model, including the `BADGE` reward type.

## Badge (User Record)

A **Badge** is the per-user record that represents an earned badge. It aggregates all instances of a specific badge being awarded to the same user.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `badgeConfigurationId` | nanoid | References the Badge Configuration |
| `userId` | nanoid | The user who earned the badge |
| `count` | number | Total number of times this badge has been awarded to this user |
| `firstAssignedAt` | ISO datetime | When the user first earned this badge |
| `lastAssignedAt` | ISO datetime | When the user most recently earned this badge |
| `defaultLang` | lang | Default language for display |
| `translation` | object | Localized label and description for the requesting user's language |
| `badgeLogs` | BadgeLog[] | Complete history of individual assignments |
| `createdAt` | ISO datetime | Record creation timestamp |
| `updatedAt` | ISO datetime | Last update timestamp |

### Count and Recurrence

The `count` field reflects how many times the badge has been assigned to the user. Badges can be earned multiple times if the triggering condition recurs — for example, completing the same recurring mission each month. Each assignment creates a new BadgeLog entry.

A `count` of 1 means the badge was earned exactly once. A higher count indicates a recurring achievement.

## Badge Log

A **BadgeLog** is an immutable record of a single badge assignment event. It provides a complete audit trail of how and when each badge instance was earned.

### Fields

| Field | Type | Description |
|-------|------|-------------|
| `sourceEntityType` | string | The type of entity that triggered the assignment (e.g., `Mission`, `LearningPath`) |
| `sourceEntityId` | nanoid | The specific entity instance that triggered the assignment |
| `rewardRuleId` | nanoid | The reward rule that processed the assignment |
| `assignedAt` | ISO datetime | When this specific assignment occurred |

The combination of `sourceEntityType` and `sourceEntityId` identifies exactly which mission completion or learning path completion triggered the badge. The `rewardRuleId` traces which rule evaluated the event.

## Example: Badge Awarded on Learning Path Completion

### Step 1: Create the Badge Configuration

```json
{
  "badgeConfigurationId": "bc-lp-onboarding",
  "name": "Onboarding Completer",
  "image": "https://cdn.example.com/badges/onboarding.png",
  "origin": "CUSTOM",
  "progressSourceEntityType": "LearningPath",
  "progressSourceEntityId": "lp-onboarding-2025",
  "defaultLang": "en",
  "langs": ["en", "it"],
  "translations": [
    { "lang": "en", "label": "Onboarding Completer", "description": "Awarded for completing the onboarding learning path." },
    { "lang": "it", "label": "Completamento Onboarding", "description": "Assegnato al completamento del percorso di onboarding." }
  ]
}
```

### Step 2: Publish the Badge Configuration

```
POST /badge-configurations/{badgeConfigurationId}/publish
```

### Step 3: Create the Reward Rule

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

### Step 4: What Happens at Runtime

1. A user completes the onboarding learning path.
2. A `LearningPathLog` event is published with `progress: COMPLETE`.
3. The reward engine evaluates the rule's `matchCondition` — it passes.
4. A badge assignment is created: the user's Badge record for `bc-lp-onboarding` is created (or `count` is incremented if they've earned it before).
5. A BadgeLog entry is written with `sourceEntityType: LearningPath`, `sourceEntityId: lp-onboarding-2025`, and the `rewardRuleId`.

### Step 5: User Retrieves Their Badges

```
GET /badges/bc-lp-onboarding
```

Response includes `count: 1`, `firstAssignedAt`, and the badgeLogs array with the single assignment event.

## Summary of Key Concepts

| Concept | Purpose |
|---------|---------|
| **BadgeConfiguration** | Template defining what the badge is, its image, translations, and what progress source it represents |
| **progressSourceEntityType** | Links the badge to a MissionConfiguration or LearningPath for frontend progress display |
| **Lifecycle** | DRAFT → PUBLISHED → ARCHIVED controls when a badge can be awarded |
| **Reward Rule (BADGE type)** | The mechanism that actually awards the badge — no expression or redemption mode needed |
| **Badge** | Per-user aggregate record: count, first/last assignment dates, full history |
| **BadgeLog** | Immutable record of each individual assignment with source entity and rule traceability |
| **count** | How many times the badge has been earned — supports recurring achievement scenarios |

## Related Domains

- **Reward and Currency Domain**: the reward rule with `rewardType: BADGE` is the mechanism that triggers badge assignment. Understanding ALWAYS/FALLBACK resolution and match conditions is essential for badge configuration.
- **Mission Domain**: mission completion is a primary trigger for badge assignment. The `progressSourceEntityType: MissionConfiguration` links a badge to a specific mission template.
- **Learning Content Domain**: learning path completion is the other primary trigger. The `progressSourceEntityType: LearningPath` links a badge to a specific learning path.
- **Cross-Cutting Patterns**: entity matching (INSTANCE/ENTITY/TAG), JsonLogic match conditions, and the CATALOG/CUSTOM origin pattern are shared with other domains.
