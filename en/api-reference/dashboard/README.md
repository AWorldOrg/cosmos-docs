# Dashboard Context API Reference

This section documents the API endpoints available in the Dashboard context of the Cosmos platform.

## Introduction

The Dashboard context provides APIs for administration and management functions, enabling account owners and administrators to configure and monitor their Cosmos environments. These APIs are designed for use in administrative interfaces and management tools.

## Authentication

All Dashboard context APIs require authentication with principal-level or administrator-level permissions. Requests must include a valid access token in the Authorization header:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

For information on obtaining access tokens, see the [Authentication Guide](../../guides/authentication.md).

### Custom Claims

The Dashboard context APIs use custom claims in the access token to enforce permissions and operations. Some of the common custom claims include (but are not limited to):
- `accountId`
- `workspaceId`
- `principalId`
- `userId`

This list is non-exhaustive and additional claims may be required depending on the specific operation. When performing a sign-in as a normal user, all necessary custom claims are automatically included in the access token.

### Machine-to-Machine (M2M) Flows

APIs that require "user level" access can also be invoked in machine-to-machine (M2M) flows using client credentials. When using M2M flows, the caller must include the userId of the user to impersonate in a header with every call:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

This allows the correct execution of "user level" APIs even in M2M implementations, where your service may need to perform actions on behalf of users. This approach is particularly useful for backend services that need to interact with the API programmatically while preserving the user context.

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

### Caching

Queries (read-only operations) in the Dashboard context leverage an internal caching mechanism to improve performance. This means that repeated identical queries may return faster as they might be served from cache.

### Idempotency

Most operations that cause side effects (like creating resources) are idempotent, and their results are cached temporarily for up to 5 minutes. This provides several benefits:

- If you submit the same mutation multiple times concurrently or within a short time window, only the first request will be fully processed.
- Subsequent identical requests within the cache period will return the same payload as the first successful call, with an additional `x-idempotency-key` header in the response.
- This prevents duplicate resource creation and helps maintain data consistency during network issues or retries.

For example, if you attempt to create the same user twice with concurrent requests or within the 5-minute window, only the first API call would succeed. Other calls would return the same payload with the added idempotency header.

After the cache expires, further identical requests will be executed again, and the business logic will determine the response. For instance, attempts to create a user after the cache has expired will likely fail because the user already exists.

### Response Compression

To reduce payload size and improve transfer times, you can enable compression by including the following header in your requests:

```
Accept-Encoding: gzip
```

### Schema Introspection

GraphQL provides introspection capabilities that allow you to explore available operations, types, and fields. You can use standard GraphQL introspection queries to discover the schema details:

```graphql
query {
  __schema {
    types {
      name
      description
    }
  }
}
```

Many GraphQL clients (for example Postman) automatically provide introspection features, allowing you to browse the schema and available operations.

> **Note**: The Cosmos API is in pre-alpha stage and undergoes frequent updates. Schema introspection is a great way to discover the latest available operations.

## Pagination

List queries in Cosmos support pagination through a Connection pattern with the following structure:

```graphql
type WorkspaceConnection {
  items: [Workspace!]!
  nextToken: String
}
```

All operations that return paginated lists return a "Connection" that contains a list of items of the relevant type and an optional `nextToken` for requesting the next page.

Example query with pagination:

```graphql
query ListWorkspaces($input: ListWorkspacesInput) {
  listWorkspaces(input: $input) {
    items {
      id
      name
      description
      environment
      status
      createdAt
    }
    nextToken
  }
}
```

The pagination input typically follows this structure:

```graphql
input ListWorkspacesInput {
  limit: Int
  nextToken: String
}
```

Example variables:

```json
{
  "input": {
    "limit": 10,
    "nextToken": "eyJsYXN0SXRlbUlkIjoiMTIzNDUiLCJsYXN0SXRlbVZhbHVlIjoidGVzdCJ9"
  }
}
```

### Pagination Guidelines

- You can specify an optional `limit` to control the number of items returned per page
- If no limit is provided, the system will use a default value
- To retrieve the next page, pass the `nextToken` from the previous response
- **Important**: A `nextToken` is only valid when used with the same `limit` that was used in the original request. You should not mix tokens returned from calls with different limit values

## Rate Limiting

At pre-alpha stage, there are not rate limits applied yet.

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
