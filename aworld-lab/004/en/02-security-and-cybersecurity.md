### Data encryption

AWorld implements end-to-end encryption to protect data both in transit and at rest, using recognized industry standards.

#### Encryption in transit

All communications between client and server are protected through standard encryption protocols:

- **Protocol**: TLS 1.2 and TLS 1.3 mandatory for all API communications
- **Coverage**: 100% of data flows between client and server (verified via AWS Config with semi-annual audits)
- **Certificates**: managed through AWS Certificate Manager with automatic renewal
- **Benefits**: protection against man-in-the-middle attacks, data interception, downgrade attacks

#### Encryption at rest

Data stored on persistent storage is protected through encryption with centralized key management:

- **Algorithm**: AES-256 for all data on persistent storage
- **Coverage**: 100% of data in Amazon DynamoDB and storage (verified via AWS Config with semi-annual audits)
- **Key management**: AWS Key Management Service (KMS) for centralized key management
- **Key rotation**: automatic according to AWS policies
- **Benefits**: data protection in case of unauthorized physical access to data centers

### API protection

API protection is articulated on multiple levels of complementary defense.

#### AWS WAF (web application firewall)

AWorld uses AWS WAF with dual-layer configuration for complete protection:

**WAF configuration**:
- **Cognito Pool WAF** (REGIONAL scope): Protects Cognito User Pool from direct attacks
- **Auth Proxy WAF** (CLOUDFRONT scope): Protects CloudFront distribution for Cognito Proxy Router
- **CloudWatch metrics**: Enabled for real-time monitoring and alerting

**Protection rules**:
- **Aggressive rate limiting**: 100 requests per 5-minute window per IP address
- **SQL injection**: Blocking malicious SQL query patterns
- **Cross-site scripting (XSS)**: Filters to prevent injection of malicious scripts
- **AWS Managed Rules**: Amazon IP Reputation List for automatic blocking of known malicious IPs
- **Sampled requests**: Logging blocked requests for post-incident analysis

#### Rate limiting and throttling

To prevent abuse and guarantee fairness in resource allocation:

- **API Gateway throttling**: configurable limits per endpoint
- **Burst capacity**: controlled management of temporary spikes
- **Fair usage**: resource guarantee for all tenants in multi-tenant environment

#### DDoS protection

The platform is natively protected against distributed denial of service attacks:

- **AWS Shield Standard**: automatic protection against common DDoS attacks (included in API Gateway)
- **Distributed rate limiting**: automatic mitigation of attack patterns
- **Automatic scaling**: absorption of attack traffic without impact on legitimate clients

#### Continuous threat monitoring

An active monitoring system constantly analyzes traffic to identify and block suspicious activity:

- **Continuous security monitoring**: dedicated platform for real-time threat detection (source: ISMS security policies)
- **Automatic detection**: behavioral analysis of API traffic
- **Real-time alerting**: immediate notifications on suspicious activity
- **Incident response**: automatic activation of countermeasures (e.g., IP blocking, aggressive throttling)

#### Vulnerability management

Structured vulnerability management system:

- **Critical vulnerabilities**: remediation within ≤ 15 days from identification (source: ISMS KPI list)
- **High vulnerabilities**: remediation within ≤ 30 days from identification (source: ISMS KPI list)
- **Penetration testing**: semi-annual security tests conducted by third parties (source: ISMS security policies)
- **Continuous scanning**: automated vulnerability monitoring via dedicated security platform

### Authentication

AWorld supports multiple authentication modes for different use cases.

#### EMAIL_OTP passwordless authentication (end users)

Passwordless authentication for end users, which reduces the attack surface and simplifies user experience.

**Authentication flow**:

1. **OTP request**:
   - User enters their email
   - AWS Cognito generates a 6-digit one-time password (OTP)
   - OTP is sent via email to the user
   - Cognito returns a temporary session token

2. **OTP verification**:
   - User enters the OTP received via email
   - System validates the OTP together with the session token
   - If valid, Cognito returns: access token, ID token, refresh token

**Expiration times**:
- **OTP**: 3 minutes
- **Session token**: 3 minutes
- **Access token**: 1 hour
- **Refresh token**: 30 days (does not change on refresh)

**Security benefits**:
- No password to remember or manage
- Single-use OTP with short expiration
- Reduced attack surface (no credential stuffing, no password reuse)
- SECRET_HASH HMAC-SHA256 for client validation with secret

#### OAuth2 client credentials (machine-to-machine)

OAuth2 standard for backend service authentication and server-to-server integrations.

**Authentication flow**:

1. Client authenticates with `client_id` and `client_secret` (Basic Auth)
2. Request to `https://auth.aworld.cloud/oauth2/token` with `grant_type=client_credentials`
3. Response contains `access_token` with configured scopes

**Available scopes**:
- `app/read`: read end-user API data
- `app/write`: write end-user API data (e.g., log activity on behalf of user)
- `dashboard/read`: read configurations and analytics
- `dashboard/write`: create/modify missions, content, users

**User impersonation**:
- M2M token can operate on behalf of specific users
- `x-user-id` header to specify user to impersonate
- Useful for batch operations that must appear as user actions

#### Cognito Proxy Router

To optimize costs and performance of OAuth2 calls, the platform implements an intelligent proxy that drastically reduces requests to Cognito:

**Architecture**:
- **CloudFront distribution**: Custom domain `auth.{CUSTOM_DOMAIN}` with selective routing
- **Lambda@Edge**: Intelligent routing for specific endpoints
- **DynamoDB caching**: Persistent storage for M2M tokens

**Token caching functionality**:

The platform implements sophisticated caching for the OAuth2 Client Credentials flow:

- **Cache key**: SHA-256 hash of Authorization header + scope (no plaintext secrets in database)
- **Storage**: DynamoDB with hashed keys for security
- **TTL strategy**: Dual TTL approach
  - Runtime validation: Checks `expiresAt > now` before return
  - DynamoDB TTL: Automatic background cleanup of expired tokens
- **TTL ratio**: Configurable (default 75% of token expiry, e.g., 1h token → 45min cache)

**Intelligent routing**:
- `/oauth2/token` → Lambda (with caching logic for client_credentials)
- `/.well-known/openid-configuration` → Lambda (cached response with URL rewriting)
- Other paths → Direct pass-through to Cognito

**Benefits**:
- Drastic reduction of Cognito calls for repeated M2M operations
- Cost optimization (each Cognito call has a cost)
- Improved performance (cache response in ~10ms vs ~100ms Cognito)
- Security: Secrets never stored in plaintext

### Authorization

#### Lambda Authorizer

Dynamic authorization mechanism for every single API request:

- **JWT token validation**: verifies signature, expiration, issuer
- **workspaceId validation**: comparison between `workspaceId` in token and requested workspace
- **Tenant isolation**: cross-workspace access blocked at API Gateway level
- **Performance**: cacheable results to reduce latency

#### RBAC (role-based access control)

Access control model based on predefined roles:

- **Owner**: maximum level of control, workspace configuration management
- **Admin**: platform configuration, user management, complete access
- **Manager**: operational management, content creation and modification
- **Member**: standard access to features
- **Viewer**: read-only access to data and analytics

Static permissions assigned per role, simplifying access management.

#### ABAC (attribute-based access control)

Evolution towards attribute-based access control for greater flexibility:

- **Dynamic permissions**: based on user attributes (e.g., Premium status, department, location)
- **Contextual conditions**: time, completion status, resource properties
- **Greater granularity**: more flexible rules compared to static RBAC
- **Scalability**: reduced need to manually manage multiple roles

#### AWS Verified Permissions

The platform uses AWS Verified Permissions for policy-based fine-grained authorization, completely separating authorization logic from application code:

**Policy Store Configuration**:
- **Policy Store**: Centralized repository of authorization policies
- **Identity Source**: Integration with Cognito via OIDC with custom claim `identityId` as principal
- **Schema Entities**: Definition of entity types (Identity, User, Resources) and Actions
- **Validation**: Policy validation engine to prevent configuration errors

**Integration Flow**:

The Lambda Authorizer integrates Verified Permissions for decision-making:

1. API Gateway receives request with JWT token
2. Lambda Authorizer extracts token and parameters (path, query)
3. Call to `IsAuthorizedWithToken` API of Verified Permissions
4. Decision engine evaluates policies with context attributes
5. Response (Allow/Deny) transformed into IAM policy for API Gateway
6. Request authorized or blocked at gateway level

**Context-Aware Authorization**:
- **Path parameters**: `workspaceId`, `resourceId` extracted from URL
- **Query parameters**: Filters and conditions passed as context
- **Custom attributes**: JWT claims (role, platform, context) evaluated in policies

**Benefits**:
- **Centralization**: Policies managed centrally, not scattered in code
- **Auditability**: Every authorization decision traced and auditable
- **Native ABAC**: Attribute-based access control beyond role-based
- **Scalability**: Adding new resource types without application code changes
- **Testing**: Policies testable independently from the application

### JWT token structure

#### Access token (TTL: 1 hour)

Token used to authorize API requests.

| Claim | Description | Security importance |
|-------|-------------|---------------------|
| `sub` | Cognito user ID | Unique user identifier |
| `workspaceId` | Workspace ID | **CRITICAL**: Multi-tenant isolation |
| `accountId` | Account ID | Tenant membership |
| `userId` | Application user ID | Application user ID |
| `context` | `"dashboard"` \| `"app"` | Authorized API context |
| `platform` | `"web"` \| `"mobile"` \| `"m2m"` | Client type |
| `role` | User role | RBAC permissions |
| `exp` | Unix timestamp | Token expiration |

**Refresh Token** (TTL: 30 days):

- Opaque token (not JWT) used to obtain new access tokens without re-authentication
- **Does not change on refresh**: remains valid until 30-day expiration
- When expired, user must re-authenticate

#### M2M Delegation with User Impersonation

Machine-to-machine clients can optionally operate on behalf of specific users, maintaining complete audit trail:

**Mechanism**:
- M2M client obtains access token with `platform: "m2m"`
- For operations on behalf of user, client passes header `X-User-ID: {userId}`
- `m2mDelegation` middleware intercepts header and validates:
  - User existence in workspace
  - User membership in current workspace
  - Permissions delegated by M2M token

**Claims Enrichment**:
The middleware enriches the original M2M claims with user information:
- `userId`: User ID to impersonate
- `principalId`: User principal ID
- `lang`, `timezone`: User preferences

**Use Cases**:
- **Bulk data import**: Synchronizations from HR/LMS systems where each operation must appear as action of the real user
- **Batch operations**: Automations that must maintain correct data ownership
- **Audit trail**: Operation traceability with real user, not just service account
- **GDPR compliance**: Data export on behalf of specific user

**Security**:
- M2M token must have scope `app/write` or `dashboard/write`
- Workspace membership validation mandatory
- Rate limiting applied both at M2M client level and impersonated user

### Security incident management

Structured incident response plan for managing anomalies and security violations:

#### Identification and isolation

The first phase of incident response focuses on rapid threat containment:

- **Automatic detection**: monitoring systems identify suspicious activity
- **Immediate isolation**: suspicious activities automatically isolated
- **Preventive blocking**: suspicious IPs or users temporarily blocked

#### Alerting and notification

The system guarantees timely communication of incidents to all involved stakeholders:

- **Real-time alerts**: notifications to security managers
- **Incident notification**: notification to interested parties within 72 hours of confirmation (source: ISMS security policies)
- **Structured escalation**: escalation procedures based on severity

#### Analysis and response

Each incident is thoroughly analyzed to prevent future recurrences:

- **Root cause analysis**: thorough analysis of incident cause
- **Corrective measures**: implementation of fixes for future event prevention
- **Documentation**: complete incident tracking for compliance

#### Operational continuity

Even during security incident management, the platform maintains service continuity:

- **Automatic failover**: traffic diversion to alternative regions in case of attack
- **Business continuity**: service maintenance even during incident response
