## Overview

AWorld Lab is a multi-tenant gamification platform providing REST APIs across two contexts: App and Dashboard.

## Prerequisites

- AWorld Lab account (via administrator or sign-up)
- Workspace ID for your environment
- Basic understanding of REST APIs
- Development environment with HTTP client

## Account and Workspace Setup

### 1. Get Access

You'll receive an invitation email with account access instructions.

### 2. User Types

- **User**: Workspace-scoped user with specific roles (admin, editor, viewer)

### 3. Workspace ID

Your `workspaceId` identifies your isolated environment. You'll need this for authentication and API calls.

Example: `abc_123-xyz`

## API Domains

- **Auth**: `https://auth.aworld.cloud`
- **API**: `https://api.eu-west-1.aworld.cloud`

> **Migration Note**: The API domain will change to `https://api.eu-west-1.aworld.cloud` on March 1, 2026. Both domains will work during the transition.

## Authentication

AWorld Lab uses AWS Cognito with EMAIL_OTP passwordless authentication. Access tokens contain critical claims including `workspaceId`, `userId`, and `role`.

### Quick Start: EMAIL_OTP

```javascript
// Step 1: Request OTP
const session = await initiateEmailOTP(email, clientId, clientSecret, region);

// Step 2: User enters OTP code from email

// Step 3: Verify OTP and get tokens
const { AccessToken, IdToken, RefreshToken } = await verifyEmailOTP(
  email,
  otpCode,
  session,
  clientId,
  clientSecret,
  region
);

// Step 4: Store tokens securely
storeTokens(AccessToken, IdToken, RefreshToken);
```

**See [Authentication](./02-authentication.md) for complete implementation including M2M flows.**

## API Contexts

AWorld Lab exposes two API contexts with different base URLs:

| Context | Base URL | Purpose | Auth Level |
|---------|----------|---------|------------|
| **Dashboard** | `/dashboard/v1/*` | Content creation & config | Admin/Editor |
| **App** | `/app/v1/*` | End-user interactions | User |

**See [API Architecture](./03-api-architecture.md) for complete context details and conventions.**

## Making Your First API Call

### REST Example: Get Missions

```javascript
async function getMissions(accessToken) {
  const response = await fetch('https://api.eu-west-1.aworld.cloud/app/v1/missions', {
    method: 'GET',
    headers: {
      'Authorization': `Bearer ${accessToken}`,
      'Accept-Encoding': 'gzip' // Enable compression
    }
  });

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  const data = await response.json();
  return data.items; // Array of missions
}
```

### REST Example: Get Single Mission

```javascript
async function getMission(missionId, accessToken) {
  const response = await fetch(
    `https://api.eu-west-1.aworld.cloud/app/v1/missions/${missionId}`,
    {
      headers: {
        'Authorization': `Bearer ${accessToken}`
      }
    }
  );

  if (!response.ok) {
    if (response.status === 404) {
      throw new Error('Mission not found');
    }
    throw new Error('Failed to fetch mission');
  }

  return await response.json();
}
```

### REST Example: Submit Quiz (App Context)

```javascript
async function submitQuiz(quizId, answers, accessToken) {
  const response = await fetch(
    `https://api.eu-west-1.aworld.cloud/app/v1/quiz/${quizId}/submit`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'x-idempotency-key': generateUUID() // Prevent duplicates
      },
      body: JSON.stringify({
        answers: answers,
        submittedAt: new Date().toISOString()
      })
    }
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return await response.json();
}
```

### REST Example: Create Mission (Dashboard Context)

```javascript
async function createMission(missionData, accessToken) {
  const response = await fetch(
    'https://api.eu-west-1.aworld.cloud/dashboard/v1/missions',
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${accessToken}`,
        'Content-Type': 'application/json',
        'x-idempotency-key': generateUUID()
      },
      body: JSON.stringify({
        name: missionData.name,
        type: missionData.type,
        description: missionData.description,
        points: missionData.points,
        status: 'draft'
      })
    }
  );

  if (!response.ok) {
    const error = await response.json();
    throw new Error(error.message);
  }

  return await response.json();
}
```

### REST Example: Pagination

```javascript
async function getAllMissions(accessToken) {
  const allMissions = [];
  let nextToken = null;
  const limit = 20;

  do {
    const url = new URL('https://api.eu-west-1.aworld.cloud/app/v1/missions');
    url.searchParams.set('limit', limit);
    if (nextToken) {
      url.searchParams.set('nextToken', nextToken);
    }

    const response = await fetch(url, {
      headers: { 'Authorization': `Bearer ${accessToken}` }
    });

    const data = await response.json();
    allMissions.push(...data.items);
    nextToken = data.nextToken;
  } while (nextToken);

  return allMissions;
}
```

## Token Management

### Check Token Expiration

```javascript
function isTokenExpired(token) {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]));
    return payload.exp * 1000 < Date.now();
  } catch {
    return true;
  }
}
```

### Auto-Refresh Access Token

```javascript
async function getValidAccessToken() {
  let accessToken = getStoredAccessToken();

  if (isTokenExpired(accessToken)) {
    console.log('Access token expired, refreshing...');
    const refreshToken = getStoredRefreshToken();
    const newTokens = await refreshAccessToken(refreshToken, clientId, clientSecret);

    accessToken = newTokens.AccessToken;
    storeTokens(newTokens.AccessToken, newTokens.IdToken, refreshToken);
  }

  return accessToken;
}
```

### API Wrapper with Auto-Refresh

```javascript
async function apiCall(url, options = {}) {
  const accessToken = await getValidAccessToken();

  const response = await fetch(url, {
    ...options,
    headers: {
      ...options.headers,
      'Authorization': `Bearer ${accessToken}`
    }
  });

  // Handle 401 by forcing token refresh
  if (response.status === 401) {
    const refreshToken = getStoredRefreshToken();
    const newTokens = await refreshAccessToken(refreshToken, clientId, clientSecret);
    storeTokens(newTokens.AccessToken, newTokens.IdToken, refreshToken);

    // Retry with new token
    return fetch(url, {
      ...options,
      headers: {
        ...options.headers,
        'Authorization': `Bearer ${newTokens.AccessToken}`
      }
    });
  }

  return response;
}
```

## Common Patterns

### Error Handling

```javascript
async function handleAPIError(response) {
  if (!response.ok) {
    const error = await response.json();

    switch (response.status) {
      case 400:
        throw new Error(`Validation error: ${error.message}`);
      case 401:
        throw new Error('Authentication required');
      case 403:
        throw new Error('Insufficient permissions');
      case 404:
        throw new Error('Resource not found');
      case 409:
        throw new Error('Resource conflict');
      case 429:
        throw new Error('Rate limit exceeded');
      default:
        throw new Error(`API error: ${error.message}`);
    }
  }

  return await response.json();
}
```

### Retry Logic with Exponential Backoff

```javascript
async function fetchWithRetry(url, options, maxRetries = 3) {
  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const response = await fetch(url, options);

      if (response.ok) {
        return await response.json();
      }

      // Don't retry client errors (4xx)
      if (response.status >= 400 && response.status < 500) {
        throw await handleAPIError(response);
      }

      // Retry server errors (5xx)
      if (attempt < maxRetries - 1) {
        const delay = Math.pow(2, attempt) * 1000; // 1s, 2s, 4s
        await new Promise(resolve => setTimeout(resolve, delay));
        continue;
      }

      throw await handleAPIError(response);
    } catch (error) {
      if (attempt === maxRetries - 1) throw error;
    }
  }
}
```

## Workspace Context

All API calls are scoped to your workspace via the `workspaceId` claim in your access token.

**Critical**: Ensure your token's `workspaceId` matches the workspace you're accessing. APIs validate this on every request.

```javascript
function getWorkspaceFromToken(accessToken) {
  const payload = JSON.parse(atob(accessToken.split('.')[1]));
  return payload.workspaceId;
}
```

## Next Steps

### Learn Key Concepts
- [Authentication](./02-authentication.md) - Complete auth flows with code
- [API Architecture](./03-api-architecture.md) - Multi-tenancy, contexts, patterns

### Explore API References
- **OpenAPI Specs**: `/packages/schemas/{context}/v1/openapi.json`
  - Dashboard: Content creation & configuration
  - App: User-facing endpoints

### Integration Best Practices
1. **Always validate tokens**: Check `exp` claim before use
2. **Implement auto-refresh**: Handle token expiration gracefully
3. **Use idempotency keys**: Prevent duplicate operations
4. **Enable compression**: Include `Accept-Encoding: gzip`
5. **Handle errors properly**: Implement retry with backoff
6. **Request only needed data**: Minimize payload size
7. **Use pagination**: Don't fetch all items at once

## Troubleshooting

### Authentication Issues

| Issue | Cause | Solution |
|-------|-------|----------|
| `401 Unauthorized` | Missing/expired token | Refresh access token |
| `403 Forbidden` | Insufficient permissions | Check user role in token claims |
| `WORKSPACE_MISMATCH` | Wrong workspaceId | Verify token's workspaceId claim |

### API Usage

| Issue | Cause | Solution |
|-------|-------|----------|
| `400 Bad Request` | Invalid input | Check error details for validation failures |
| `404 Not Found` | Resource doesn't exist | Verify resource ID |
| `409 Conflict` | Duplicate resource | Check if resource already exists |
| `422 Unprocessable` | Semantic validation error | Review business logic constraints |

### Common Mistakes

1. **Not checking token expiration**: Always validate `exp` claim
2. **Hardcoding workspaceId**: Extract from token, don't assume
3. **Missing idempotency keys**: Can cause duplicate resources
4. **Ignoring error details**: Error responses contain helpful info
5. **Not using pagination**: Fetching too much data at once

## Support

- **Documentation**: Refer to Authentication and API Architecture docs
- **OpenAPI Specs**: Complete endpoint reference in monorepo
- **Support**: Contact your account administrator

## Quick Reference

**Auth Domain**: `https://auth.aworld.cloud`

**API Domain**: `https://api.eu-west-1.aworld.cloud`
_(Migrates to `https://api.aworld.cloud` on March 1, 2026)_

**API Contexts**:
- Dashboard: `/dashboard/v1/*`
- App: `/app/v1/*`

**Token TTL**:
- Access Token: 1 hour
- Refresh Token: 30 days

**Required Headers**:
```
Authorization: Bearer {accessToken}
Content-Type: application/json
Accept-Encoding: gzip
x-idempotency-key: {uuid} (for mutations)
```
