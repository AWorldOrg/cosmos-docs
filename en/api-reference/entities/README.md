# Cosmos Entities

> **Important**: This detailed documentation is provided for demonstration purposes. Always refer to the GraphQL schema (using introspection) for the most up-to-date API documentation. The schemas evolve over time, and introspection will always provide the current definition.

This section provides in-depth documentation for the core entities in the Cosmos platform. Each entity is documented in detail with information about its data model, lifecycle, usage patterns across different contexts, and best practices.

## Purpose

While the context-specific API documentation (App, Dashboard, and Portal) focuses on the operations available in each context, this section focuses on the entities themselves. It provides a comprehensive view of each entity, regardless of which context it's being accessed from.

This approach helps you understand:

- The complete data model for each entity
- How entities relate to each other
- The full lifecycle of each entity
- How to work with entities across different contexts
- Common patterns and best practices for each entity type
- Technical considerations specific to each entity

## Available Entities

The following entities are documented in this section:

- [Quizzes](./quizzes.md) - Interactive assessment units used throughout the platform
- Users (coming soon) - User accounts within workspaces
- Workspaces (coming soon) - Isolated environments within accounts
- Accounts (coming soon) - Top-level organization units

## Related Documentation

- [App Context API](../app/README.md) - API operations for end-user applications
- [Dashboard Context API](../dashboard/README.md) - API operations for administrative interfaces
- [Portal Context API](../portal/README.md) - API operations for platform-level management
- [Common API Features](../common-features.md) - Features shared across all contexts
