# Cosmos Documentation

Welcome to the official documentation for the Cosmos SaaS platform.

## Contents

- [Introduction](#introduction)
- [API Reference](#api-reference)
- [Guides](#guides)
- [Authentication](#authentication)
- [Key Concepts](#key-concepts)

## Introduction

Cosmos is a multi-tenant SaaS platform that offers a suite of APIs across three distinct contexts: App, Dashboard, and Portal. The platform is designed with a user-centric approach while also supporting machine-to-machine (M2M) interactions through client credentials.

## API Reference

Detailed documentation for all available APIs:

- [App Context API Reference](./api-reference/app/README.md) - APIs for the application context
- [Dashboard Context API Reference](./api-reference/dashboard/README.md) - APIs for the dashboard context
- [Portal Context API Reference](./api-reference/portal/README.md) - APIs for the portal context

## Guides

Step-by-step guides for common tasks:

- [Getting Started](./guides/getting-started.md)
- [Authentication & Authorization](./guides/authentication.md)
- [Working with Workspaces](./guides/workspaces.md)
- [Understanding Multi-tenancy](./guides/multi-tenancy.md)

## Authentication

Cosmos uses AWS Cognito with a custom domain for authentication, implementing standard OAuth2 flows. For detailed instructions on authentication, see our [Authentication Guide](./guides/authentication.md).

## Key Concepts

### Account

An account represents a tenant in the multi-tenant architecture of Cosmos. Each organization typically has its own account, which serves as the top-level container for all resources related to that organization.

### Workspace

Each account can have multiple workspaces, which are isolated environments within an account. Common workspace configurations include:
- Development
- Staging
- Production

Workspaces allow for separation of resources and access controls within the same account.

### Principal

A principal is a platform-level user who has access across accounts and workspaces. While principals can manage multiple accounts, most commonly they manage multiple workspaces within a single account. Principals typically represent administrators or super-users with elevated permissions.

### User

A user is scoped to a specific workspace within an account. Users have permissions limited to their assigned workspace and typically represent regular users of the platform.

## API Types

Cosmos provides both GraphQL and REST APIs:

- **GraphQL APIs**: Currently available API type, offering flexible queries and mutations
- **REST APIs**: Will have feature parity with GraphQL APIs but are not published yet
