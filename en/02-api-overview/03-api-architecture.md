## API Domains

- **Auth**: `https://auth.aworld.cloud`
- **API**: `https://api.eu-west-1.aworld.cloud`

> **Migration Note**: The API domain will migrate to `https://api.aworld.cloud` on March 1, 2026. Both domains will work during the transition period.

**Note**: Code examples in this document use generic URLs (`https://api.aworld.cloud`). Use `https://api.eu-west-1.aworld.cloud` until March 1, 2026.

## Multi-Tenant Architecture

AWorld Lab uses a hierarchical multi-tenant model where each organization operates in isolation.

### Hierarchy

```
Platform
└── Account (Tenant)
    └── Workspace
        └── User
```

- **Platform**: Top-level AWorld system
- **Account**: Isolated tenant (organization/company)
- **Workspace**: Environment within account (dev/staging/prod)
- **User**: Workspace-scoped user with specific roles

### Data Isolation

Each account's data is logically separated:

- Accounts cannot access each other's data
- Isolation enforced at database and API layers
- Each workspace within an account is also isolated
- `workspaceId` in JWT token controls data access

**Critical**: All API requests validate `workspaceId` claim matches requested resources. Cross-workspace access is blocked at API gateway level.

## Workspaces

Workspaces provide isolated environments within an account.

### Common Patterns

- **Development**: Build and test features
- **Staging**: Pre-production QA
- **Production**: Live environment for end-users

Or organized by:
- Teams/departments
- Client projects
- Business units
- Application types

### Workspace Resources

Each workspace has isolated:
- **Users**: Workspace-scoped with specific roles
- **Configuration**: Workspace-specific settings
- **Data**: Missions, activities, leaderboards, users
- **Credentials**: Separate Cognito app client per workspace
- **Logs**: Workspace-specific operational data

### Best Practices

1. **Naming**: Use consistent patterns (e.g., `project-env`, `team-workspace`)
2. **Separation**: Keep dev/staging/prod completely separate
3. **Access**: Limit production access to essential personnel
4. **Cleanup**: Archive unused workspaces regularly

## API Contexts

AWorld Lab exposes two API contexts, each with different access levels and purposes.

| Aspect | Dashboard API | App API |
|--------|---------------|---------|
| **Base URL** | `/dashboard/v1/*` | `/app/v1/*` |
| **Audience** | Content managers | End users |
| **Auth Level** | Admin/Editor | User-level |
| **Required Claims** | `userId`, `workspaceId` | `userId`, `workspaceId` |
| **Use Cases** | Content creation & configuration | Missions, leaderboards, activities |

### Dashboard API

Content management and configuration for workspace administrators.

**Example endpoints**:
```
GET    /dashboard/v1/missions
POST   /dashboard/v1/missions
PUT    /dashboard/v1/missions/{missionId}
POST   /dashboard/v1/missions/{missionId}/publish
POST   /dashboard/v1/activities
GET    /dashboard/v1/users
```

**Required token claims**: `userId`, `workspaceId`, `role` (admin/editor)

### App API

Consumer-facing endpoints for end users.

**Example endpoints**:
```
GET    /app/v1/missions
GET    /app/v1/missions/{missionId}
GET    /app/v1/activities
GET    /app/v1/runtime-leaderboards
GET    /app/v1/runtime-leaderboards/{id}/rankings
POST   /app/v1/quiz/{quizId}/submit
```

**Required token claims**: `userId`, `workspaceId`

## REST API Conventions

### Resource Naming

- **Plural nouns**: `/missions`, `/activities`, `/leaderboards`
- **Kebab-case**: `/runtime-leaderboards`, `/quiz-submissions`
- **Lowercase**: No camelCase or PascalCase in paths

### HTTP Methods

| Method | Purpose | Example |
|--------|---------|---------|
| `GET` | Retrieve resource(s) | `GET /missions` |
| `POST` | Create resource or execute action | `POST /missions`, `POST /missions/{id}/publish` |
| `PUT` | Full resource replacement | `PUT /missions/{id}` |
| `PATCH` | Partial resource update | `PATCH /missions/{id}` |
| `DELETE` | Delete resource | `DELETE /missions/{id}` |

### Action Endpoints

Non-CRUD operations use POST with action name:

```
POST   /missions/{id}/publish
POST   /missions/{id}/archive
POST   /missions/{id}/duplicate
POST   /quiz/{id}/submit
POST   /leaderboards/{id}/reset
```

### Path vs Query Parameters

**Path parameters**: Resource identifiers
```
GET /missions/{missionId}
GET /activities/{activityId}
```

**Query parameters**: Filtering, pagination, sorting
```
GET /missions?status=published&limit=20&offset=0
GET /users?role=admin&workspaceId=abc123
```

### Example REST Endpoint Structure

```
# List resources
GET    /missions?limit=20&offset=0

# Get single resource
GET    /missions/{missionId}

# Create resource (Dashboard only)
POST   /missions
Body: { "name": "Mission Name", "type": "quiz", ... }

# Update resource (Dashboard only)
PUT    /missions/{missionId}
Body: { "name": "Updated Name", ... }

# Partial update (Dashboard only)
PATCH  /missions/{missionId}
Body: { "status": "published" }

# Execute action
POST   /missions/{missionId}/publish
Body: { "scheduledAt": "2026-03-01T00:00:00Z" }

# Delete resource (Dashboard only)
DELETE /missions/{missionId}
```

## Common Patterns

### Pagination

List endpoints use connection pattern with `limit`, `offset`, and `nextToken`.

**Request**:
```javascript
GET /missions?limit=20&offset=0
```

**Response**:
```json
{
  "items": [
    { "id": "mission1", "name": "..." },
    { "id": "mission2", "name": "..." }
  ],
  "nextToken": "eyJsYXN0SXRlbUlkIjoibWlzc2lvbjIwIn0",
  "total": 150
}
```

**Next page**:
```javascript
GET /missions?limit=20&nextToken=eyJsYXN0SXRlbUlkIjoibWlzc2lvbjIwIn0
```

**Important**: `nextToken` must be used with the same `limit` value. Don't mix tokens from different limits.

### Idempotency

Mutations that create or modify resources support idempotency via `x-idempotency-key` header.

**Request**:
```javascript
POST /missions
Headers:
  Authorization: Bearer {token}
  x-idempotency-key: unique-request-id-12345
Body: { "name": "New Mission", ... }
```

**Behavior**:
- First request: Processes normally, returns 201 Created
- Duplicate requests (same key, within 5 minutes): Returns cached response with `x-idempotency-cache-hit: true` header
- After 5 minutes: Cache expires, request processed again (may fail if resource exists)

**Best practice**: Generate idempotency keys using UUIDs or similar unique identifiers.

### Versioning

APIs use explicit versioning in URL path (`/v1/`, `/v2/`):
```
https://api.aworld.cloud/app/v1/missions
https://api.aworld.cloud/dashboard/v1/missions
```

Version changes occur only for breaking changes. Non-breaking updates are deployed without version increments.

### Response Compression

Enable gzip compression for faster transfers:

**Request**:
```
Accept-Encoding: gzip
```

APIs automatically compress responses when this header is present.

### Caching

Read-only queries leverage ElastiCache for performance:

- Frequently accessed mission configurations cached
- User profile data cached temporarily
- Leaderboards updated in real-time (not cached)
- Cache automatically invalidated on resource updates

**Cache control**: Responses include standard HTTP cache headers (`Cache-Control`, `ETag`).

### Rate Limiting

**Current status (pre-alpha)**: No rate limits enforced

**Future implementation**: Per-workspace throttling based on:
- Requests per second (RPS)
- Requests per minute (RPM)
- Concurrent connections

## Data Validation

### ID Formats

All IDs use nanoid format (21 characters, URL-safe):
```
userId: "V1StGXR8_Z5jdHi6B-myT"
missionId: "3z4v7K9pL2qR5sT8xY1nW"
workspaceId: "abc_123-xyz"
```

### String Rules

| Field | Min Length | Max Length | Pattern |
|-------|------------|------------|---------|
| Name | 2 | 50 | Unicode letters, spaces, hyphens, apostrophes |
| Email | 5 | 254 | Valid email format |
| Description | 0 | 2000 | UTF-8 text |

**Name validation**:
- Supports multiple scripts (Latin, Chinese, Arabic, etc.)
- No consecutive spaces
- Cannot start/end with spaces

### Timestamps

All timestamps use ISO 8601 format in UTC:
```json
{
  "createdAt": "2026-02-17T14:30:00Z",
  "updatedAt": "2026-02-17T15:45:30Z",
  "scheduledAt": "2026-03-01T00:00:00Z"
}
```

### Language Codes

ISO 639-1 language codes:
```
"en" (English)
"it" (Italian)
"fr" (French)
"es" (Spanish)
"zh-CN" (Chinese Simplified)
"zh-TW" (Chinese Traditional)
```

### Timezones

IANA timezone identifiers:
```
"UTC"
"Europe/Rome"
"America/New_York"
"Asia/Tokyo"
```

## Error Handling

### HTTP Status Codes

| Code | Meaning | When Used |
|------|---------|-----------|
| `200` | OK | Successful GET/PUT/PATCH |
| `201` | Created | Successful POST (resource created) |
| `204` | No Content | Successful DELETE |
| `400` | Bad Request | Invalid input, validation errors |
| `401` | Unauthorized | Missing or invalid access token |
| `403` | Forbidden | Valid token but insufficient permissions |
| `404` | Not Found | Resource doesn't exist |
| `409` | Conflict | Resource already exists, state conflict |
| `422` | Unprocessable Entity | Semantic validation errors |
| `429` | Too Many Requests | Rate limit exceeded (future) |
| `500` | Internal Server Error | Unexpected server error |

### Error Response Format

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid mission name",
    "details": [
      {
        "field": "name",
        "message": "Name must be between 2 and 50 characters"
      }
    ]
  }
}
```

### Common Error Codes

| Code | Description | Solution |
|------|-------------|----------|
| `INVALID_TOKEN` | Access token expired or invalid | Refresh token or re-authenticate |
| `WORKSPACE_MISMATCH` | Token workspaceId doesn't match request | Verify correct workspace context |
| `INSUFFICIENT_PERMISSIONS` | User lacks required role | Check user role and permissions |
| `RESOURCE_NOT_FOUND` | Requested resource doesn't exist | Verify resource ID |
| `DUPLICATE_RESOURCE` | Resource already exists | Use different identifier or update existing |
| `VALIDATION_ERROR` | Input validation failed | Check error details for specific fields |

## Best Practices

### API Integration

1. **Always validate workspaceId**: Ensure token's `workspaceId` matches intended workspace
2. **Use idempotency keys**: Prevent duplicate resource creation
3. **Handle token expiration**: Implement automatic token refresh
4. **Request only needed fields**: Minimize response payload size
5. **Implement pagination**: Don't fetch all items at once
6. **Use compression**: Include `Accept-Encoding: gzip` header
7. **Handle errors gracefully**: Implement retry logic with exponential backoff

### Security

1. **Never log access tokens**: Tokens contain sensitive user information
2. **Validate JWT claims**: Check `exp`, `workspaceId`, and `userId` on every request
3. **Use HTTPS only**: All API calls must use HTTPS in production
4. **Implement CSRF protection**: Use state parameter in OAuth flows
5. **Rotate credentials**: Regularly update client secrets
6. **Monitor suspicious activity**: Log failed auth attempts

### Performance

1. **Cache responses**: Leverage HTTP cache headers
2. **Batch requests**: Combine multiple operations when possible
3. **Use pagination**: Limit result sets to reasonable sizes
4. **Minimize payload**: Request only required fields
5. **Implement connection pooling**: Reuse HTTP connections
6. **Monitor latency**: Track API response times

### Data Management

1. **Use ISO 8601 timestamps**: All dates in UTC
2. **Validate IDs**: Check format before making requests
3. **Handle timezone conversions**: Convert to user's timezone in UI
4. **Support multiple languages**: Use `lang` claim from token
5. **Implement soft deletes**: Mark resources as deleted instead of removing
6. **Audit changes**: Log all create/update/delete operations

## OpenAPI Specifications

Complete REST endpoint documentation is available in OpenAPI format:

**Location**: `/packages/schemas/{context}/v1/openapi.json` in monorepo

**Contexts**:
- **Dashboard**: `/packages/schemas/dashboard/v1/openapi.json`
- **App**: `/packages/schemas/app/v1/openapi.json`

Use these specs with tools like Swagger UI, Postman, or code generators for complete endpoint reference.
