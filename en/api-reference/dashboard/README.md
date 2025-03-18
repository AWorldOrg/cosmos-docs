# Dashboard Context API Reference

This section documents the API endpoints available in the Dashboard context of the Cosmos platform.

## Introduction

The Dashboard context provides APIs for administration and management functions, enabling account owners and administrators to configure and monitor their Cosmos environments. These APIs are designed for use in administrative interfaces and management tools.

## Authentication

The Dashboard context uses the common authentication mechanisms described in [Common API Features](../common-features.md#authentication-basics). Dashboard APIs specifically require principal-level or administrator-level permissions.

### M2M Implementation Details

For Dashboard context APIs that require "user level" access in machine-to-machine (M2M) flows, you must include the userId of the user to impersonate in a header with every call:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

This allows your service to perform actions on behalf of specific users while using client credentials for authentication.

## API Endpoints

### GraphQL API

The primary API for the Dashboard context is a GraphQL API:

**Current Endpoint:** `https://v1.gql.dashboard.aworld.cloud/graphql`

> **Note**: These endpoints are currently exposing internal APIs directly to customers. In the future, all APIs will be accessible through a single reverse proxy, and these endpoints will change.

### API Versioning

- **GraphQL**: GraphQL APIs typically use a rolling updates approach without formal versioning until breaking changes occurs. This allows the API to evolve while maintaining backward compatibility. During this pre-alpha stage, more significant changes may occur, but once stable, changes will follow the rolling approach.

- **REST**: REST APIs (when published) will use explicit versioning (e.g., v1, v2). The version numbers will be aligned with GraphQL whenever REST requires updates.

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** TBD

## GraphQL Schema

The Dashboard context GraphQL API provides the following main types of operations:

1. **Queries**: For retrieving data about users, quizzes, and workspace resources
2. **Mutations**: For creating and updating resources

### Administrative Context

When authenticated, your API requests operate within the context of:

- The authenticated **Principal** (platform-level user)
- The **Account** you have access to manage
- The specific **Workspace** you are currently working with

## Schema Details

### Scalar Types

- `AWSDateTime`, `AWSDate`, `AWSTime`, `AWSTimestamp`
- `AWSEmail`, `AWSJSON`, `AWSURL`, `AWSPhone`, `AWSIPAddress`
- `Long`

### Interfaces

```graphql
interface Node {
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

interface Connection {
  items: [Node]
  nextToken: String
}
```

### User Types

```graphql
type User {
  userId: ID!
  principalId: String!
  workspaceId: String!
  accountId: String!
  externalId: String
  lang: String!
  timezone: String!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type UserConnection {
  items: [User!]!
  nextToken: String
}

input CreateUserInput {
  email: AWSEmail!
  firstName: String
  lastName: String
  lang: String
  timezone: String
  externalId: String
}
```

### Quiz Types

```graphql
enum QuizDifficulty {
  EASY
  MEDIUM
  HARD
}

enum QuizAnswer {
  opt1
  opt2
  opt3
  opt4
}

enum QuizOrigin {
  CATALOG
  CUSTOM
}

enum QuizPlacement {
  STANDALONE
  STORY
  NEWS
}

type Quiz {
  quizId: ID!
  difficulty: QuizDifficulty!
  answer: QuizAnswer!
  syncWithCatalog: Boolean
  origin: QuizOrigin!
  placement: QuizPlacement!
  quizCatalogId: ID!
  translations: [QuizTranslation!]!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}

type QuizTranslation {
  quizId: ID!
  lang: String!
  opt1: String!
  opt2: String!
  opt3: String
  opt4: String
  question: String!
  explanation: String
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

## Common Queries

### List Users

Retrieve users in the current workspace:

```graphql
query ListUsers($nextToken: String) {
  users(nextToken: $nextToken) {
    items {
      userId
      principalId
      workspaceId
      accountId
      externalId
      lang
      timezone
      createdAt
      updatedAt
    }
    nextToken
  }
}
```

### List Quizzes

Retrieve quizzes with pagination:

```graphql
query ListQuizzes($input: ListQuizzesInput) {
  quizzes(input: $input) {
    items {
      quizId
      difficulty
      answer
      origin
      placement
      quizCatalogId
      syncWithCatalog
      createdAt
      updatedAt
      translations {
        lang
        question
        opt1
        opt2
        opt3
        opt4
        explanation
      }
    }
    nextToken
  }
}
```

## Common Mutations

### Create User

Create a new user in the current workspace:

```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    userId
    principalId
    workspaceId
    accountId
    externalId
    lang
    timezone
    createdAt
    updatedAt
  }
}
```

Example variables:

```json
{
  "input": {
    "email": "user@example.com",
    "firstName": "John",
    "lastName": "Doe",
    "lang": "en",
    "timezone": "Europe/Rome",
    "externalId": "ext-12345"
  }
}
```

## API Features

The Dashboard context implements the common API features described in [Common API Features](../common-features.md). Please refer to that document for detailed information about:

- [Caching](../common-features.md#caching)
- [Idempotency](../common-features.md#idempotency)
- [Response Compression](../common-features.md#response-compression)
- [Schema Introspection](../common-features.md#schema-introspection)

For the Dashboard context, idempotency is especially critical for administrative operations like user creation and workspace management. For example, if you attempt to create the same user or workspace twice within the 5-minute idempotency window, only the first API call would succeed. This prevents duplicate resource creation during admin operations, which could otherwise cause significant issues.

## Pagination

The Dashboard context follows the standard pagination approach described in [Common API Features](../common-features.md#pagination).

For pagination guidelines and best practices, refer to the [Common API Features](../common-features.md#pagination-guidelines) documentation.

## Rate Limiting

Please refer to the [Common API Features](../common-features.md#rate-limiting) documentation for information about rate limiting.

## Administrative Operations

The Dashboard context provides several administrative operations for managing the platform:

### User Management

- Creating, updating, and deactivating users
- Assigning roles and permissions
- Managing user access to workspaces

### Workspace Management

- Creating and configuring workspaces
- Setting workspace-specific configurations
- Monitoring workspace status and usage

### Account Configuration

- Managing account settings
- Configuring security policies
- Setting up integrations with other systems

## Best Practices

1. **Use GraphQL variables** for dynamic values rather than string interpolation
2. **Request only the fields you need** to minimize response size and processing time
3. **Implement error handling** to gracefully handle different error scenarios
4. **Use pagination** for large result sets to improve performance
5. **Secure administrative endpoints** by implementing proper authorization checks

## Example Integration

Here's an example of integrating with the Dashboard context API in a JavaScript application:

```javascript
async function fetchAccountWorkspaces(accountId) {
  const query = `
    query GetAccountWorkspaces($accountId: ID!) {
      account(id: $accountId) {
        id
        name
        workspaces {
          id
          name
          environment
          status
        }
      }
    }
  `;

  const response = await fetch('https://v1.gql.dashboard.aworld.cloud/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
    },
    body: JSON.stringify({
      query,
      variables: { accountId }
    })
  });

  const result = await response.json();
  
  if (result.errors) {
    console.error('GraphQL errors:', result.errors);
    throw new Error(result.errors[0].message);
  }
  
  return result.data;
}
```

## Additional Resources

- [GraphQL Documentation](https://graphql.org/learn/)
- [Dashboard Context Schema Explorer](#) (requires authentication)
- [API Changelog](#) (requires authentication)
