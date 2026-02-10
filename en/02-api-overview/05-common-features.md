This page documents common features and behaviors shared across all AWorld API contexts (Consumer/App, Admin/Dashboard, and Portal). Refer to the specific context documentation for context-specific details.

## Authentication Basics

All AWorld APIs require authentication using a valid access token. Requests must include an Authorization header:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

For information on obtaining access tokens, see the [Authentication](apidog://link/pages/1215379).

### Custom Claims

AWorld APIs use custom claims in the access token to enforce permissions and operations. When performing a sign-in, all necessary custom claims are automatically included in the access token.

Each context requires specific claims:
- **App Context**: `accountId`, `workspaceId`, `principalId`, `userId`, and others
- **Dashboard Context**: `accountId`, `workspaceId`, `principalId`, `userId`, and others
- **Portal Context**: `principalId` and others

Refer to each context's documentation for specific claim requirements.

### Machine-to-Machine (M2M) Flows

APIs can be invoked in machine-to-machine (M2M) flows using client credentials. The implementation details vary by context:

- **App and Dashboard Contexts**: Requires the `x-user-id` header to impersonate a user
- **Portal Context**: Operates at the platform level with principal-level permissions

See the specific context documentation for detailed implementation guidance.

## API Versioning

### GraphQL

GraphQL APIs typically use a rolling updates approach without formal versioning until breaking changes occur. This allows the API to evolve while maintaining backward compatibility. During this pre-alpha stage, more significant changes may occur, but once stable, changes will follow the rolling approach.

### REST

REST APIs (when published) will use explicit versioning (e.g., v1, v2). The version numbers will be aligned with GraphQL whenever REST requires updates.

## API Features

### Caching

Queries (read-only operations) leverage an internal caching mechanism to improve performance. This means that repeated identical queries may return faster as they might be served from cache.

### Idempotency

Most operations that cause side effects (like creating resources) are idempotent, and their results are cached temporarily for up to 5 minutes. This provides several benefits:

- If you submit the same mutation multiple times concurrently or within a short time window, only the first request will be fully processed.
- Subsequent identical requests within the cache period will return the same payload as the first successful call, with an additional `x-idempotency-key` header in the response.
- This prevents duplicate resource creation and helps maintain data consistency during network issues or retries.

After the cache expires, further identical requests will be executed again, and the business logic will determine the response. For instance, attempts to create a resource after the cache has expired will likely fail because the resource already exists.

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

> **Note**: The AWorld API is in pre-alpha stage and undergoes frequent updates. Schema introspection is a great way to discover the latest available operations.

## Pagination

List queries in AWorld support pagination through a Connection pattern with the following structure:

```graphql
type ResourceConnection {
  items: [Resource!]!
  nextToken: String
}
```

All operations that return paginated lists return a "Connection" that contains a list of items of the relevant type and an optional `nextToken` for requesting the next page.

Example query with pagination:

```graphql
query ListResources($input: ListResourcesInput) {
  listResources(input: $input) {
    items {
      id
      name
      # Other fields...
    }
    nextToken
  }
}
```

The pagination input typically follows this structure:

```graphql
input ListResourcesInput {
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

At pre-alpha stage, there are no rate limits applied yet.

## Data Validation

AWorld APIs employ strict validation for all data inputs to ensure consistency, security, and data integrity. Understanding these validation rules helps you build more robust integrations.

### Common Types and Validation Rules

The system enforces specific validation rules for different types of data:

#### Identifiers

- **Account IDs, Workspace IDs**: Must be exactly the specified length, containing only alphanumeric characters, underscores, and hyphens
- **User IDs, Principal IDs**: Must be valid nanoid format
- **Client IDs**: Non-empty string identifiers

#### String Data

- **Names**: 
  - Must be 2-50 characters
  - Can contain letters from multiple scripts (Latin, Chinese, Arabic, etc.)
  - May include hyphens, apostrophes, and spaces
  - Cannot contain consecutive spaces

#### Timestamps

- **Created/Updated At**: Must be valid ISO datetime strings

#### Language Codes

- Language codes follow IETF language tags
- Typically simple codes like "en" or "fr" 
- Some exceptions like Chinese which uses "zh-TW" and "zh-CN"

#### Timezones

- All timezone values must be valid IANA timezone identifiers (e.g., "Europe/Rome", "America/New_York")

### Validation Behavior

When validation fails, the API returns appropriate error responses with details about the validation failure. These responses include:

- The field that failed validation
- A description of why the validation failed
- Any constraints or expected formats

This information helps you quickly identify and fix data issues in your requests.

## Language Selection

For user-facing APIs (like the App context), entities will return data and metadata in a single language. The language selection mechanism works as follows:

1. The language is determined by the `lang` custom claim in the access token
2. This claim is set automatically when a user signs in, based on their profile preferences
3. All content will be returned in the language specified by this claim
4. If content is not available in the requested language, it may fall back to a default language (typically English)

> **Important**: If a user changes their language preference in their profile, the access token needs to be refreshed to retrieve content in the newly selected language. Simply changing the profile setting without getting a new token will not affect API responses.

This behavior applies to all translatable content in the system, including quiz questions and answers, UI text, and any other localized resources.

## Best Practices

1. **Use GraphQL variables** for dynamic values rather than string interpolation
2. **Request only the fields you need** to minimize response size and processing time
3. **Implement error handling** to gracefully handle different error scenarios
4. **Use pagination** for large result sets to improve performance
5. **Secure endpoints** by implementing proper authorization checks
6. **Handle token refresh** when user preferences change (for example, to ensure content is delivered in the preferred language, selected timezone is respected, etc)
