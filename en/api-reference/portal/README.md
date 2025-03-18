# Portal Context API Reference

This section documents the API endpoints available in the Portal context of the Cosmos platform.

## Introduction

The Portal context provides APIs for platform-level operations that principals (platform-level users) can perform to manage accounts and perform cross-account operations. These APIs are designed for use in administrative portals and cross-account management tools.

## Authentication

All Portal context APIs require authentication with principal-level permissions. Requests must include a valid access token in the Authorization header:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

For information on obtaining access tokens, see the [Authentication Guide](../../guides/authentication.md).

### Custom Claims

The Portal context APIs use custom claims in the access token to enforce permissions and operations. Some of the common custom claims include (but are not limited to):
- `principalId`

This list is non-exhaustive and additional claims may be required depending on the specific operation. When performing a sign-in as a principal, all necessary custom claims are automatically included in the access token.

### Machine-to-Machine (M2M) Flows

Portal context APIs can be invoked in machine-to-machine (M2M) flows using client credentials. Unlike the App and Dashboard contexts which operate within a user context, the Portal context operates at the platform level, typically with principal-level permissions.

When using M2M flows with the Portal API, ensure your client credentials have the appropriate platform-level permissions. This approach is particularly useful for platform-level automation and administration tools that need to manage accounts programmatically.

## API Endpoints

### GraphQL API

The primary API for the Portal context is a GraphQL API:

**Current Endpoint:** `https://v1.gql.portal.aworld.cloud/graphql`

> **Note**: These endpoints are currently exposing internal APIs directly to customers. In the future, all APIs will be accessible through a single reverse proxy, and these endpoints will change.

### API Versioning

- **GraphQL**: GraphQL APIs typically use a rolling updates approach without formal versioning until breaking changes occurs. This allows the API to evolve while maintaining backward compatibility. During this pre-alpha stage, more significant changes may occur, but once stable, changes will follow the rolling approach.

- **REST**: REST APIs (when published) will use explicit versioning (e.g., v1, v2). The version numbers will be aligned with GraphQL whenever REST requires updates.

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** TBD

## GraphQL Schema

The Portal context GraphQL API provides the following type of operations:

1. **Mutations**: For creating platform-level resources

Currently, no Query operations are implemented in the Portal context.

### Schema Details

```graphql
type Account {
  accountId: ID!
  name: String!
  adminEmail: AWSEmail!
  billingEmail: AWSEmail!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

input CreateAccountInput {
  name: String!
  adminEmail: String!
  billingEmail: String!
}

type Query {} 

type Mutation {
  createAccount(input: CreateAccountInput!): Account!
}

schema {
  query: Query
  mutation: Mutation
}
```

### Principal Context

When authenticated, your API requests operate within the context of:

- The authenticated **Principal** (platform-level user)
- The **Platform** configuration and settings
- The **Accounts** you have access to manage

## Common Mutations

### Create Account

Create a new account:

```graphql
mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    accountId
    name
    adminEmail
    billingEmail
    createdAt
    updatedAt
  }
}
```

Example variables:

```json
{
  "input": {
    "name": "Example Organization",
    "adminEmail": "admin@example.com",
    "billingEmail": "billing@example.com"
  }
}
```

## API Features

### Caching

Queries (read-only operations) in the Portal context leverage an internal caching mechanism to improve performance. This means that repeated identical queries may return faster as they might be served from cache.

### Idempotency

Most operations that cause side effects (like creating resources) are idempotent, and their results are cached temporarily for up to 5 minutes. This provides several benefits:

- If you submit the same mutation multiple times concurrently or within a short time window, only the first request will be fully processed.
- Subsequent identical requests within the cache period will return the same payload as the first successful call, with an additional `x-idempotency-key` header in the response.
- This prevents duplicate resource creation and helps maintain data consistency during network issues or retries.

For example, if you attempt to create the same account twice with concurrent requests or within the 5-minute window, only the first API call would succeed. Other calls would return the same payload with the added idempotency header.

After the cache expires, further identical requests will be executed again, and the business logic will determine the response. For instance, attempts to create an account after the cache has expired will likely fail because the account already exists.

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
type AccountConnection {
  items: [Account!]!
  nextToken: String
}
```

All operations that return paginated lists return a "Connection" that contains a list of items of the relevant type and an optional `nextToken` for requesting the next page.

Example query with pagination:

```graphql
query ListAccounts($input: ListAccountsInput) {
  listAccounts(input: $input) {
    items {
      id
      name
      status
      createdAt
      updatedAt
    }
    nextToken
  }
}
```

The pagination input typically follows this structure:

```graphql
input ListAccountsInput {
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

## Platform Operations

The Portal context provides several platform-level operations:

### Account Management

- Creating, updating, and suspending accounts
- Managing account settings and configurations
- Viewing account usage metrics and status

### Principal Management

- Creating and managing platform-level users (principals)
- Assigning roles and permissions to principals
- Managing principal access to accounts

### Platform Configuration

- Configuring platform-wide settings
- Managing available roles and permissions
- Setting up platform-level integrations

## Best Practices

1. **Use GraphQL variables** for dynamic values rather than string interpolation
2. **Request only the fields you need** to minimize response size and processing time
3. **Implement error handling** to gracefully handle different error scenarios
4. **Use pagination** for large result sets to improve performance
5. **Secure platform-level endpoints** with proper authorization checks

## Example Integration

Here's an example of integrating with the Portal context API in a JavaScript application:

```javascript
async function fetchAvailableAccounts() {
  const query = `
    query GetAccounts {
      accounts {
        id
        name
        status
        createdAt
        workspaceCount
      }
    }
  `;

  const response = await fetch('https://v1.gql.portal.aworld.cloud/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
    },
    body: JSON.stringify({ query })
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
- [Portal Context Schema Explorer](#) (requires authentication)
- [API Changelog](#) (requires authentication)
