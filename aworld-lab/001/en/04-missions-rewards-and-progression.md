This section covers the **engine** of AWorld Lab's *gamification* system: the rules, rewards, and progression mechanics that give meaning to user actions. Missions turn activities into goals, virtual currencies quantify progress, and reward rules automate incentives — creating a complete engagement loop. For the foundational activities and content that feed into these mechanics, refer to the activities and content documentation.

## Missions

**Missions** are the primary mechanism for turning user activities into structured goals. A mission defines a **target** — a specific number or combination of activities to complete — and tracks progress toward that target. When the target is reached, the mission is completed, and downstream rewards and recognitions are triggered.

### Mission Types: Individual and Group

AWorld Lab supports two mission types:

- **Individual missions**: assigned to a single user, tracking their personal progress toward the goal.
- **Group missions**: assigned to a group of users identified by a shared tag, tracking **collective progress** across all group members. This enables team challenges where collaboration drives completion.

### Mission Lifecycle: States and Timeframes

Every mission follows a **state-based lifecycle**:

- **Pending**: the mission exists but its start date has not yet arrived.
- **Active**: the mission is within its timeframe and accepting progress.
- **Ended**: the mission's timeframe has expired.

Missions support three **timeframe configurations**:

- **Permanent**: no end date — the mission remains active indefinitely.
- **Range**: a fixed start and end date — ideal for time-limited campaigns.
- **Recurring**: missions that reset and repeat at regular intervals — perfect for weekly or monthly engagement cycles.

### Mission Matching and Progress Tracking

The mission system uses a flexible **matching engine** to determine which user actions count toward progress. Each mission specifies:

- **Match type**: whether to match a specific activity instance, any activity of a certain type, or activities associated with a specific tag.
- **Match entity**: the type of trackable action to monitor — activities, quizzes, or tags.
- **Match condition**: a configurable expression that filters which events qualify (e.g., "only quizzes with outcome success" or "only activities with a specific tag").

When a matching event occurs, the system applies an **increment expression** to calculate how much progress to add, and compares the result against a **target expression** that determines the completion threshold.

This architecture enables missions ranging from simple ("Complete 10 activities") to sophisticated ("Accumulate 500 points from quizzes with difficulty above 3, within the current month").

Each progress update is recorded in the **Mission Log**, providing a complete audit trail of how the mission was completed.

### Mission Rules and Assignment Modes

Rather than manually assigning missions to individual users, AWorld Lab provides a **rules engine** that automates mission distribution:

- **Mission Configurations** act as templates, defining the matching logic, progress rules, and metadata for a type of mission.
- **Mission Rules** determine how and when these templates are instantiated as actual missions for users.

Rules support different **assignment modes**:

- **Lazy**: missions are created on-demand when a user browses available missions. If the user matches the rule's conditions, the mission is generated in real time. This is ideal for discovery-driven experiences.
- **Event**: missions are assigned automatically when a specific event occurs — for example, assigning a follow-up mission when the user completes a Learning Path. Combined with recurring timeframes, this also enables campaign-style deployment at predetermined intervals.

Each rule includes **user targeting conditions** that determine which users are eligible, allowing precise segmentation by tags, attributes, or behavior.

### Configurable Rules with JSONLogic

AWorld Lab's mission system is powered by a **flexible expression language** for defining conditions, increments, and targets. This means:

- **Match conditions** can filter events by any combination of attributes — entity type, outcome, tags, difficulty, or custom metadata.
- **Increment expressions** can assign different progress values based on context — for example, awarding double progress for activities completed during a promotional period.
- **Target expressions** can dynamically calculate goals — for instance, setting the target based on the user's level or group size.

This configurability enables clients to design complex engagement mechanics without code changes, adapting missions to any business context through configuration alone.

### Group Missions

**Group missions** enable collaborative challenges where multiple users contribute toward a shared goal. The mission is assigned to a **group tag**, and every qualifying action from any user in that group increments the shared counter.

This unlocks team-based engagement scenarios:

- **Department challenges**: teams within an organization compete to complete the most activities.
- **Community goals**: an entire user community works toward a collective milestone.
- **Event-based collaboration**: participants at a conference or campaign pool their progress toward a common target.

Group mission progress is tracked per-user in the Mission Log, allowing visibility into both individual contributions and collective achievement.

## Virtual Currencies

AWorld Lab's point system is built on a **multi-currency model** that goes beyond simple point accumulation. Each workspace can define **multiple virtual currencies**, each serving a different strategic purpose — from experience-based progression to spendable credits.

### Multi-Currency Model

A virtual currency is defined by:

- **Name and icon**: display identity for the currency.
- **Balance constraints**: optional minimum and maximum balance limits to control the economy.
- **Origin**: currencies can come from AWorld Lab's **catalog** (pre-configured) or be **custom**-defined by the client.
- **Multi-language support**: currency names and descriptions localized for different markets.

> A typical configuration uses two currencies: **experience points** that drive leaderboard rankings and **credits** that are earned from mission completion and redeemable for rewards. However, clients can define any number of currencies to fit their engagement model.

### Virtual Balance and Transactions

Each user maintains a **virtual balance** per currency, tracking:

- **Total amount**: the cumulative balance.
- **Available amount**: the balance available for spending, excluding pending or frozen transactions.

All balance changes are processed through **virtual transactions**, which provide a complete financial-grade record of every credit and debit:

- **Direction**: Credit (adding to balance) or Debit (subtracting from balance).
- **Initiator**: who or what caused the transaction — a **reward rule**, a **streak rule**, a **system** process, an **admin** action, or the **user** themselves.
- **Counterpart**: the other party in the transaction (user or system).

### Transaction Lifecycle and Automation

Each transaction follows a **state lifecycle**:

- **Pending**: the transaction has been created but not yet finalized.
- **Completed**: the transaction is finalized and reflected in the balance.
- **Expired**: the transaction was not redeemed within its validity period.
- **Rejected**: the transaction was denied (e.g., insufficient balance for a debit).

Transactions support two **redemption modes**:

- **Auto**: the transaction is immediately finalized upon creation — typical for reward payouts.
- **Manual**: the transaction requires explicit user or admin action to finalize — useful for prize redemption flows.

Transactions can also carry an **expiration date**, enabling time-limited rewards that encourage prompt engagement.

### Practical Configurations

The multi-currency model supports a wide range of engagement strategies:

- **Competition-focused**: a single experience currency drives leaderboard rankings, with no spending mechanism.
- **Reward-focused**: credits are earned and spent on prizes, without affecting competitive standings.
- **Hybrid**: experience points track engagement while credits provide a parallel economy for rewards.
- **Multi-dimensional**: specialized currencies for different program areas — training points, sustainability credits, loyalty tokens — each with independent balance management.

Each client retains full control over how currencies are generated, distributed, and used, building an economy aligned with their strategic goals.

## Reward Rules

**Reward Rules** automate the distribution of virtual currency based on user actions. When a user completes an activity, finishes a quiz, reaches a mission goal, or completes a Learning Path, the reward engine evaluates all applicable rules and distributes the corresponding rewards.

### Rule Structure and Match Entities

Each reward rule defines:

- **Rule type**: whether the rule matches a specific instance, any entity of a type, or entities associated with a tag.
- **Match entity**: the type of action that triggers the reward — **Mission**, **Activity**, **Quiz**, **Learning Path**, **Learning Group**, **Slide**, or **Tag**.
- **Match condition**: a configurable expression that filters which events qualify for the reward.
- **Rewards**: one or more currency payouts, each targeting a specific virtual currency with a calculated amount.

A single rule can distribute **multiple rewards** simultaneously — for example, granting both experience points and credits when a mission is completed.

### Application Modes and Multi-Reward Configuration

Rules operate in different **application modes**:

- **Always**: the reward is granted every time the conditions are met.
- **Fallback**: the reward is only granted if no other rules matched the same event — useful for providing a baseline reward.
- **Disabled**: the rule is inactive.

Reward amounts are calculated using **configurable expressions**, enabling dynamic payouts based on context. For instance, a rule could award more points for quizzes with higher difficulty, or bonus credits during a promotional period.

Like other platform elements, reward rules support both **catalog** (pre-built) and **custom** origins.

## Achievements: Badges and Levels

The **Achievements** system provides visible progression and recognition, motivating users beyond points and rewards.

**Badges** are static recognitions awarded when a user reaches specific milestones — completing a series of missions, participating in an event, or logging a certain number of actions. Once earned, a badge remains in the user's profile as permanent proof of achievement.

**Levels** represent a configurable progression system tied to **accumulated virtual currency** within a specific currency line. As users earn points, they advance through levels, each representing a higher engagement tier. Levels can unlock new features, grant access to exclusive content, or provide additional benefits within the *gamification* system.

Clients can design structured progression paths by defining level thresholds, providing users with clear targets and a visible sense of advancement.

## Tags and Entity Targeting

**Tags** are a foundational building block in AWorld Lab, used across the entire platform for **categorization, targeting, and segmentation**.

### Tag Model: Namespace and Variant

Each tag is defined by a **namespace** and **variant**, enabling structured categorization:

- **Namespace**: the category or domain (e.g., "department", "region", "tier").
- **Variant**: the specific value within that namespace (e.g., "marketing", "europe", "gold").

This structure allows clients to create organized, hierarchical tag systems without naming conflicts.

### Cross-Entity Tag Assignments

Tags can be assigned to virtually any entity in the platform — **users, activities, quizzes, Learning Paths, Learning Groups, slides, mission configurations, mission rules, streak configurations, and streak rules**. Each assignment includes a **priority** value for ordering.

This flexibility means a single tag can connect users to content, missions to activities, and reward rules to specific contexts — creating a powerful targeting fabric across the entire *gamification* system.

### Tags in Missions, Rewards, and Streaks

Tags play a critical role in the platform's rule engines:

- **Mission matching**: missions can be configured to track activities associated with specific tags, enabling thematic challenges.
- **Reward targeting**: reward rules can match events by tag, applying different rewards to different categories of content.
- **Streak configuration**: streak rules can target specific user segments based on tags.
- **User segmentation**: tags on users enable group-targeted missions, community leaderboards, and differentiated engagement paths.

## Event-Driven Gamification

AWorld Lab's *gamification* mechanics are connected through an **event-driven architecture** that ensures every user action automatically ripples through the entire system.

### Event Flow

When a user performs an action — completing an activity, finishing a quiz, reaching a mission target — the platform generates an **event** that flows through a processing pipeline:

1. The action is recorded as a log entry (Activity Log, Quiz Log, etc.).
2. The log entry triggers an event that is routed to all relevant handlers.
3. Each handler evaluates the event against its rules and applies the appropriate mechanics.

### How Events Connect the System

This event flow creates a **seamless chain reaction**:

- A user **completes a quiz** → an Activity Log is created.
- The **mission engine** evaluates whether the action counts toward any active missions → mission progress is updated.
- If a mission is **completed**, a Mission Log is created → this triggers the reward engine.
- The **reward engine** evaluates reward rules → virtual currency is credited to the user's balance.
- The **streak engine** evaluates whether the action extends the user's streak → streak count is updated.
- **Leaderboard rankings** are recalculated based on the updated currency balances.

This architecture means clients only need to configure the rules — the platform handles the real-time orchestration automatically, ensuring that every action is recognized and rewarded without manual intervention.
