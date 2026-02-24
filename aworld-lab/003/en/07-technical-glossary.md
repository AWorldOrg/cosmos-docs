### Architectural terms

**Active-active**: multi-region configuration where all regions are simultaneously operational.

**Multi-tenant**: architecture where multiple clients (tenants) share the same infrastructure with logical isolation.

**Serverless**: architectural model where the cloud provider automatically manages resource allocation without manual server provisioning.

**Workspace**: isolated environment for a client (production, staging, dev).

### Security terms

**ABAC (Attribute-Based Access Control)**: access control based on dynamic user attributes and context.

**JWT (JSON Web Token)**: standard for authentication/authorization tokens containing cryptographically signed claims.

**MFA (Multi-Factor Authentication)**: authentication requiring multiple forms of identity verification.

**OTP (One-Time Password)**: single-use password valid for single session or transaction.

**RBAC (Role-Based Access Control)**: access control based on predefined roles with static permissions.

**WAF (Web Application Firewall)**: firewall that inspects HTTP traffic to block web attacks.

### Compliance terms

**DPA (Data Processing Agreement)**: agreement defining roles and responsibilities in personal data processing.

**GDPR (General Data Protection Regulation)**: European regulation on personal data protection.

**ISMS (Information Security Management System)**: information security management system according to ISO 27001.

**Privacy by Design**: principle that integrates privacy from system design.

**RPO (Recovery Point Objective)**: maximum amount of data that can be lost in disaster scenario.

**RTO (Recovery Time Objective)**: maximum time to restore service after disaster.

### Operational terms

**Failover**: automatic process of switching to backup system in case of primary failure.

**Health check**: automatic service status monitoring for failure detection.

**Throttling**: request rate limitation to prevent abuse and guarantee fair usage.

### Gamification terms

**Activity**: a trackable user action (TDA) that feeds into the gamification system. Can be catalog-sourced or custom-defined.

**Achievement**: visible recognition awarded for reaching milestones. Includes badges (static rewards) and levels (progression tiers).

**JSONLogic**: flexible expression language used across the platform for defining conditions, calculations, and rules without code changes.

**Leaderboard Configuration**: template defining what is ranked in a leaderboard — user selection, metric aggregation, and score computation.

**Learning Group (LPG)**: a sub-section within a Learning Path that organizes related content items (slides, quizzes) with independent completion rules.

**Learning Path (LP)**: linear microlearning experience composed of heterogeneous items (slides, quizzes, learning groups, activities). Supports catalog, AI, and custom origins.

**Mission**: a structured goal that tracks user progress toward a target. Supports individual and group types with configurable matching, timeframes, and assignment rules.

**Mission Rule**: automated rule that assigns missions to users based on conditions. Supports lazy, event-driven, and scheduled assignment modes.

**Reward Rule**: automated rule that distributes virtual currency when specific conditions are met. Can match missions, activities, quizzes, learning paths, and other entities.

**Runtime Leaderboard**: a specific instance of a leaderboard configuration, bound to a timeframe (permanent, range, or recurring) with its own state lifecycle.

**Streak**: a measure of user consistency over time, tracking consecutive engagement periods (days or weeks). Supports freeze, perfect periods, and goal targets.

**Tag**: a namespace-variant pair used for categorization and targeting across entities (users, activities, missions, content).

**TDA (Tractable Digital Activity)**: any trackable user action that can trigger gamification dynamics.

**Virtual Currency**: a configurable point type within a workspace, with independent balance tracking, transaction history, and constraints.
