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

## API Endpoints

### GraphQL API

The primary API for the Portal context is a GraphQL API:

**Endpoint:** `https://api.aworld.cloud/portal/graphql`

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** `https://api.aworld.cloud/portal`

## GraphQL Schema

The Portal context GraphQL API provides the following main types of operations:

1. **Queries**: For retrieving data across multiple accounts
2. **Mutations**: For creating, updating, or deleting platform-level resources

### Principal Context

When authenticated, your API requests operate within the context of:

- The authenticated **Principal** (platform-level user)
- The **Platform** configuration and settings
- The **Accounts** you have access to manage

## Common Queries

### List Accounts

Retrieve a list of accounts available to the authenticated principal:

```graphql
query ListAccounts {
  accounts {
    id
    name
    status
    createdAt
    updatedAt
    workspaceCount
  }
}
```

### Principal Profile

Retrieve information about the currently authenticated principal:

```graphql
query GetPrincipalProfile {
  me {
    id
    email
    firstName
    lastName
    roles {
      id
      name
    }
    permissions
  }
}
```

### Account Details

Retrieve detailed information about a specific account:

```graphql
query GetAccountDetails($id: ID!) {
  account(id: $id) {
    id
    name
    status
    createdAt
    updatedAt
    settings {
      allowUserRegistration
      requireMfa
      sessionTimeout
    }
    workspaces {
      id
      name
      environment
      status
    }
    users {
      totalCount
      activeCount
    }
  }
}
```

## Common Mutations

### Create Account

Create a new account:

```graphql
mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    id
    name
    status
    createdAt
  }
}
```

Example variables:

```json
{
  "input": {
    "name": "Example Organization",
    "adminEmail": "admin@example.com",
    "settings": {
      "allowUserRegistration": true,
      "requireMfa": false,
      "sessionTimeout": 3600
    }
  }
}
```

### Update Principal Role

Update the role of a principal:

```graphql
mutation UpdatePrincipalRole($id: ID!, $input: UpdatePrincipalRoleInput!) {
  updatePrincipalRole(id: $id, input: $input) {
    id
    email
    roles {
      id
      name
    }
  }
}
```

Example variables:

```json
{
  "id": "principal-123",
  "input": {
    "roleIds": ["role-admin"]
  }
}
```

### Suspend Account

Suspend an account:

```graphql
mutation SuspendAccount($id: ID!) {
  suspendAccount(id: $id) {
    id
    name
    status
  }
}
```

## API Features

### Caching

Queries (read-only operations) in the Portal context leverage an internal caching mechanism to improve performance. This means that repeated identical queries may return faster as they might be served from cache.

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

List queries typically support pagination parameters:

```graphql
query GetPaginatedAccounts($first: Int, $after: String) {
  accounts(first: $first, after: $after) {
    edges {
      node {
        id
        name
        status
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

Example variables:

```json
{
  "first": 10,
  "after": "cursor_from_previous_page"
}
```

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

  const response = await fetch('https://api.aworld.cloud/portal/graphql', {
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
