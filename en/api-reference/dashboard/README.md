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

## API Endpoints

### GraphQL API

The primary API for the Dashboard context is a GraphQL API:

**Endpoint:** `https://api.aworld.cloud/dashboard/graphql`

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** `https://api.aworld.cloud/dashboard`

## GraphQL Schema

The Dashboard context GraphQL API provides the following main types of operations:

1. **Queries**: For retrieving data about accounts, workspaces, users, and system configuration
2. **Mutations**: For creating, updating, or deleting resources and configurations

### Administrative Context

When authenticated, your API requests operate within the context of:

- The authenticated **Principal** (platform-level user)
- The **Account** you have access to manage
- The specific **Workspace** you are currently working with

## Common Queries

### Account Information

Retrieve information about an account:

```graphql
query GetAccount($id: ID!) {
  account(id: $id) {
    id
    name
    status
    createdAt
    updatedAt
    workspaces {
      id
      name
      environment
    }
  }
}
```

### Account Users

Retrieve users associated with an account:

```graphql
query GetAccountUsers($accountId: ID!) {
  account(id: $accountId) {
    id
    name
    users {
      id
      email
      firstName
      lastName
      roles {
        id
        name
      }
      workspace {
        id
        name
      }
    }
  }
}
```

### Workspace Information

Retrieve detailed information about a workspace:

```graphql
query GetWorkspace($id: ID!) {
  workspace(id: $id) {
    id
    name
    description
    environment
    status
    createdAt
    updatedAt
    account {
      id
      name
    }
    users {
      id
      email
      firstName
      lastName
    }
  }
}
```

## Common Mutations

### Create Workspace

Create a new workspace within an account:

```graphql
mutation CreateWorkspace($input: CreateWorkspaceInput!) {
  createWorkspace(input: $input) {
    id
    name
    description
    environment
    status
    createdAt
  }
}
```

Example variables:

```json
{
  "input": {
    "accountId": "account-123",
    "name": "Production Environment",
    "description": "Production workspace for live applications",
    "environment": "PRODUCTION"
  }
}
```

### Invite User

Invite a user to join a workspace:

```graphql
mutation InviteUser($input: InviteUserInput!) {
  inviteUser(input: $input) {
    id
    email
    status
    expiresAt
  }
}
```

Example variables:

```json
{
  "input": {
    "email": "user@example.com",
    "workspaceId": "workspace-123",
    "roleIds": ["role-456"]
  }
}
```

### Update Account Settings

Update settings for an account:

```graphql
mutation UpdateAccountSettings($id: ID!, $input: UpdateAccountSettingsInput!) {
  updateAccountSettings(id: $id, input: $input) {
    id
    name
    settings {
      allowUserRegistration
      requireMfa
      sessionTimeout
    }
  }
}
```

Example variables:

```json
{
  "id": "account-123",
  "input": {
    "settings": {
      "allowUserRegistration": true,
      "requireMfa": true,
      "sessionTimeout": 3600
    }
  }
}
```

## Error Handling

GraphQL responses may include errors within the `errors` array:

```json
{
  "errors": [
    {
      "message": "Not authorized to access this resource",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["account"],
      "extensions": {
        "code": "FORBIDDEN"
      }
    }
  ],
  "data": null
}
```

Common error codes:

- `UNAUTHENTICATED`: Missing or invalid authentication
- `FORBIDDEN`: Authentication valid but insufficient permissions
- `BAD_USER_INPUT`: Invalid input parameters
- `NOT_FOUND`: Requested resource not found

## Pagination

List queries typically support pagination parameters:

```graphql
query GetPaginatedWorkspaces($accountId: ID!, $first: Int, $after: String) {
  account(id: $accountId) {
    workspaces(first: $first, after: $after) {
      edges {
        node {
          id
          name
          environment
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
```

Example variables:

```json
{
  "accountId": "account-123",
  "first": 10,
  "after": "cursor_from_previous_page"
}
```

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

  const response = await fetch('https://api.aworld.cloud/dashboard/graphql', {
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
