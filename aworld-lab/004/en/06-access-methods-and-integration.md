AWorld exposes functionality through REST API with dual-context architecture to separate administrative and end-user access.

### REST API

#### Endpoint domains

The platform exposes two main domains for authentication and API:

- **Auth domain**: `https://auth.aworld.cloud`
- **API domain**: `https://api.aworld.cloud`

#### Two API contexts

APIs are organized in two distinct contexts to separate administrative and user access:

**Dashboard API** (`/dashboard/v1/*`):
- **Target**: administrators and workspace content managers
- **Functionality**: mission management, users, groups, analytics, configurations
- **Authorization**: Admin, Editor
- **Endpoints**: 40+ endpoints for platform management

**App API** (`/app/v1/*`):
- **Target**: end-user applications (web app, mobile app)
- **Functionality**: mission participation, leaderboards, user profile, activity log
- **Authorization**: User, Admin
- **Endpoints**: 30+ endpoints for user interaction

#### REST conventions

APIs follow standard REST conventions for consistency and predictability:

- **HTTP methods**: GET, POST, PUT, PATCH, DELETE
- **Resource naming**: plural kebab-case (e.g., `/runtime-leaderboards`)
- **Versioning**: explicit in URL (`/v1/`, `/v2/`)
- **ID format**: nanoid (21 URL-safe characters)

#### Integration patterns

The platform supports various integration patterns to adapt to different use scenarios:

**Client-to-Server (C2S)**:
- Direct calls from frontend (web app, mobile app)
- Authentication via JWT token in Authorization header

**Server-to-Server (S2S)**:
- Backend calls with M2M OAuth2 token
- User impersonation via `x-user-id` header

**Pagination**:
- Connection pattern with `limit`, `offset`, `nextToken`
- Avoids excessive result sets

**Idempotency**:
- `x-idempotency-key` header for duplicate prevention
- Idempotency keys cached for 5 minutes

### Pre-provisioning and user access

> **Note**: Functionality available on request as configurable option for enterprise clients.

To minimize IT impact and guarantee security, AWorld supports user pre-provisioning flow with passwordless access.

#### Initial setup (bulk import)

The pre-provisioning process begins with a massive upload of authorized users:

1. Client provides CSV file with authorized employee emails
2. AWorld imports users into dedicated workspace Cognito system
3. Only pre-provisioned users can request access (whitelist)

#### Ongoing management

After initial setup, user management can occur in incremental mode:

- **Administration backoffice**: individual new user registration
- **Upload updated lists**: periodic CSV imports
- **Dynamic link**: works immediately for newly added users

#### Security gate

Pre-provisioning acts as a security filter that verifies authorization in real-time:

- Externally shared link is unusable for unauthorized users
- System blocks OTP sending to email addresses not in whitelist
- Pre-provisioning acts as "security gate" for authorized user perimeter

### Trigger access mode

> **Note**: Functionality available on request as configurable option for enterprise clients.

#### Option A: parametric redirect (query string)

This mode allows direct access without client-side development:

```
https://{accountURL}/login?email={user-email}&autotrigger=true
```

- Email passed as visible parameter in URL
- System reads parameter, verifies whitelist, automatically sends OTP

#### Option B: passage via custom header

For scenarios requiring greater privacy, email can be transmitted via HTTP header:

- Client makes POST request to login endpoint
- Email injected in agreed HTTP header (e.g., `X-AWorld-User-Email`)
- API Gateway configured to extract email from header

### Support for future protocols

The architecture is designed for future evolution with support for modern protocols like GraphQL.

#### GraphQL-ready architecture

Architecture designed to support GraphQL as additional API layer:

- **Greater data control**: client requests only necessary fields
- **Aggregation**: information from multiple sources in single query
- **Bandwidth reduction**: optimization for mobile clients
- **Timeline**: 2026-2027 product roadmap

### Single sign-on (SSO) and SAML

#### Native Cognito support

The AWS Cognito authentication platform offers native support for standard SSO protocols:

- **SAML 2.0**: integration with enterprise identity providers
- **OpenID Connect (OIDC)**: modern standard for SSO

#### Enterprise SSO integration

For enterprise clients with existing identity providers, it is possible to configure dedicated SSO integration:

- **Supported identity providers**: Azure AD, Google Workspace
- **Dedicated configuration**: specific setup for enterprise deployments
- **Protocols**: SAML 2.0, OIDC

SSO integration is particularly useful for organizations that want:

- Companies with existing identity provider
- Single sign-on to simplify employee access
- Centralized identity management

### Middleware stack and error handling

The platform uses a standardized middleware pipeline based on Middy to guarantee consistent behavior across all API endpoints.

#### Middleware Pipeline

Each REST Lambda handler is wrapped in standardized middleware stack that executes transversal operations:

**Pipeline Order** (sequential execution):
1. **CORS**: Adding CORS headers for cross-origin requests
2. **Inject Lambda Context**: Logger with correlation ID for end-to-end request tracing
3. **M2M Delegation**: User impersonation via `X-User-ID` header (if present)
4. **Parser**: Zod validation of input (path params, query params, body)
5. **Request Logger**: Structured logging of request with parsed input and claims
6. **Handler Execution**: Business logic execution
7. **Response Formatter**: Wrapping response in standard API Gateway format
8. **Error Handler**: Exception conversion to structured error response

**Middleware Approach Benefits**:
- **Consistency**: Uniform behavior across all APIs
- **Separation of concerns**: Cross-cutting concerns separated from business logic
- **Testability**: Each middleware testable independently
- **Maintainability**: Centralized changes without touching individual handlers

#### Standardized Error Codes System

The platform implements a structured error code system for robust client error handling:

**Error Code Categories**:
- **`auth/*`**: Authentication/authorization errors
  - `auth/invalid_token`: Invalid or malformed JWT token
  - `auth/expired_token`: Expired token, refresh necessary
  - `auth/invalid_credentials`: Incorrect credentials
  - `auth/insufficient_permissions`: User does not have permissions for operation

- **`validation/*`**: Input validation errors
  - `validation/invalid_input`: Schema validation failure (Zod)

- **`resource/*`**: Resource management errors
  - `resource/not_found`: Resource not found (404)
  - `resource/already_exists`: Resource already exists (409)
  - `resource/conflict`: Resource state conflict

- **`business/*`**: Business logic errors
  - `business/invalid_operation`: Operation not allowed for current state
  - `business/precondition_failed`: Operation preconditions not satisfied

- **`rate_limit/*`**: Rate limiting errors
  - `rate_limit/exceeded`: Request limit exceeded

- **`server/*`**: Server-side errors
  - `server/internal_error`: Generic internal error (500)
  - `server/database_error`: Database operation error
  - `server/external_service_error`: External service error

**Structured Error Response**:

Each error returns structured JSON response:

```json
{
  "code": "auth/invalid_token",
  "message": "Token signature is invalid",
  "status": 401,
  "requestId": "abc-123-def-456",
  "timestamp": "2026-02-18T10:30:00Z",
  "path": "/app/v1/missions",
  "url": "https://api.aworld.cloud/app/v1/missions",
  "docs": "https://docs.aworld.cloud/errors/auth/invalid_token"
}
```

**Idempotency Header Echo**:
- Response includes `X-Idempotency-Key` echoed back to client
- Client can verify that request was processed correctly
- Useful for debugging and troubleshooting distributed systems
