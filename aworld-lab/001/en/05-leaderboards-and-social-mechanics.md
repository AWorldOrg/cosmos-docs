This section covers AWorld Lab's **social and competitive mechanics** — the features that add a community dimension to the engagement experience. Leaderboards turn point accumulation into a dynamic competitive experience, groups enable team-based targeting, and comprehensive logging provides measurable progress visibility. For individual goal-tracking mechanics including missions and streaks, see the missions and progression documentation. For the foundational activities and content, refer to the activities documentation.

## Leaderboards

AWorld Lab's leaderboard system turns virtual currency accumulation into a **dynamic competitive experience**, allowing users to compare scores in real time. The system is built on a **two-layer architecture** that separates what is ranked from when and how it is displayed.

### Two-Layer Architecture: Configuration and Runtime

The leaderboard system consists of two distinct components:

- **Leaderboard Configuration**: a template that defines **what** is ranked — which users are included, which metrics are aggregated, and how scores are calculated.
- **Runtime Leaderboard**: an instance that defines **when** the ranking applies — the timeframe, recurrence, and current state.

This separation allows a single configuration to power multiple runtime instances. For example, a "Top Points This Week" configuration can automatically generate a new weekly leaderboard instance every Monday, each with its own independent rankings.

### Leaderboard Configuration

Each configuration defines a **query specification** that determines how rankings are computed:

- **User selection**: which users are eligible for the leaderboard, filtered by any user attribute or tag.
- **Metric aggregation**: which data to aggregate — typically virtual currency transactions, but configurable to include other metrics.
- **Score computation**: how the final score is calculated from aggregated data.
- **Ranking**: the order in which users are ranked (typically by score, descending).

Additional display settings include:

- **Top N**: the number of users to display (configurable from 1 to 100).
- **Show rank**: whether to display the user's numerical position.
- **Show score**: whether to display the computed score value.

### Runtime Instances: Timeframes and Recurrence

Each runtime leaderboard instance operates within a defined timeframe:

- **Permanent**: the leaderboard runs indefinitely with a cumulative ranking.
- **Range**: the leaderboard is active within a specific start and end date — ideal for campaigns or events.
- **Recurring**: the leaderboard automatically resets at regular intervals.

Recurring leaderboards support multiple **recurrence patterns**:

- **Daily**: rankings reset every day.
- **Weekly**: rankings reset every week.
- **Monthly**: rankings reset every month.
- **Custom**: recurrence defined by a custom schedule.

Each instance follows a **state lifecycle**: **Pending** (before start), **Active** (accepting and computing rankings), and **Ended** (final rankings frozen).

### Computation Model

Leaderboard scores are **computed at query time** using aggregation queries against the platform's analytical data store. This approach ensures that:

- Rankings always reflect the **most current data** without synchronization delays.
- Configurations can define **arbitrary scoring formulas** — not just simple sums, but weighted calculations, filtered aggregations, and custom expressions.
- The system can be backed by different computation engines depending on the deployment requirements, from SQL-based analytical stores for flexibility to in-memory databases for high-frequency update scenarios.

### Segmentation and Display

Rather than offering fixed leaderboard types, AWorld Lab's configuration model enables **any segmentation** through query definitions:

- **Global leaderboards**: include all users in the workspace, encouraging broad competition.
- **Community leaderboards**: filter users by group tags, fostering competition among peers — such as departments, teams, or geographic regions.
- **Mission leaderboards**: scope rankings to users participating in a specific mission, with a timeframe matching the mission's duration.
- **Custom segments**: any combination of user attributes and tags can define a leaderboard audience.

This flexibility allows clients to create targeted competitive experiences for every context, from company-wide challenges to intimate team competitions.

## Groups and User Clusters

AWorld Lab provides a **tag-based grouping system** that allows clients to organize users into distinct clusters based on attributes, roles, or organizational criteria.

### Tag-Based Grouping

Tags can represent any meaningful classification: departments, project teams, user tiers, geographic regions, or participation levels. The system supports **assigning multiple tags to each user**, enabling flexible and overlapping group structures. For detailed information about the tag model, see the tags and entity targeting section in the missions documentation.

### Group-Targeted Mechanics

This grouping mechanism integrates directly with the platform's competitive features:

- **Group missions**: missions assigned to users matching specific tag combinations, enabling differentiated engagement paths for different segments.
- **Community leaderboards**: leaderboards scoped to users within a specific group, fostering competition among peers rather than across the entire user base.
- **Collective progress tracking**: clients can measure the aggregate impact and participation of tagged user clusters, providing visibility into team performance.

The grouping system adapts to various organizational models — from **internal corporate initiatives** segmented by team or department, to **public programs** targeting specific user categories. Each client retains full control over how groups are defined and how they interact with the broader *gamification* system.

## Progress Tracking and Impact Measurement

A defining feature of AWorld Lab's *gamification* infrastructure is the ability to **monitor user progress in detail** and measure the impact of completed actions.

### Comprehensive Logging

The platform maintains a **complete audit trail** across every *gamification* domain:

- **Activity Logs**: every action performed, with outcomes, values, and timestamps.
- **Mission Logs**: progress updates and completion events for every mission.
- **Learning Path Logs**: start, progress, and completion states for every learning experience.
- **Learning Group Logs**: per-section progress within Learning Paths.
- **Quiz Logs**: every quiz attempt with answers, outcomes, and difficulty.
- **Slide Logs**: content viewing and completion tracking.
- **Streak Logs**: streak status changes and contribution history.

This logging architecture ensures that every user interaction is captured and available for analysis.

### Data-Driven Engagement Insights

The comprehensive logging system provides clients with the data needed to:

- **Measure individual progress**: track each user's journey across activities, missions, and learning experiences.
- **Analyze collective impact**: aggregate participation metrics across groups, departments, or the entire user base.
- **Optimize engagement strategies**: identify which missions, content, and reward structures drive the highest participation.
- **Report on outcomes**: generate evidence-based reports on the impact of *gamification* programs.

Through this layer, the platform not only increases **user engagement** but also provides **detailed metrics on the impact of user actions**, turning *gamification* into a powerful, measurable growth lever for businesses and organizations.
