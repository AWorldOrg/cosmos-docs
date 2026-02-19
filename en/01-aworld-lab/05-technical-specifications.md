## 1. Cloud infrastructure and architecture

### 1.1 Architecture overview

AWorld implements a fully serverless cloud-native architecture on Amazon Web Services (AWS), designed to guarantee unlimited scalability, high availability, and optimized costs. The architecture is organized in functional layers that separate responsibilities and facilitate platform evolution:

- **Account & user layer**: identity management, permissions, authentication (AWS Cognito), and server-to-server integration
- **Gamification layer**: core engine for engagement mechanics (missions, levels, leaderboards, badges, points)
- **Catalog layer**: distribution and organized management of training content

The multi-tenant architecture guarantees rigorous data isolation between clients, with each workspace operating in complete logical independence while sharing the underlying physical infrastructure for operational efficiency.

### 1.2 AWS technology stack

The platform is based on AWS managed services, which guarantee high standards of security, reliability, and reduced infrastructure maintenance requirements.

| Component | AWS Service | Function |
|-----------|-------------|----------|
| **Compute** | AWS Lambda | Serverless execution of API functions |
| **API management** | Amazon API Gateway | Routing, throttling, request authentication |
| **Primary database** | Amazon DynamoDB | NoSQL database with tenant-scoped composite keys |
| **Dedicated database** | Cloudflare D1 | Dedicated database for indexing and specific application functions |
| **Caching/Leaderboard** | AWS MemoryDB for Redis | In-memory system for real-time leaderboards |
| **Media storage** | Cloudflare R2 | Media storage with automatic caching and redundant CloudFront |
| **DNS/routing** | AWS Route 53 | Multi-region geographic load balancing |
| **Authentication** | AWS Cognito | Identity management and user pools |
| **Authorization** | AWS Verified Permissions | Policy-based fine-grained authorization |
| **Feature flags** | AWS AppConfig | Feature flags with safe deployment strategies |
| **Event bus** | Amazon EventBridge | Multi-region event-driven architecture |
| **Configuration** | AWS SSM Parameter Store | Cross-stage configuration management |
| **Monitoring** | AWS CloudWatch | Metrics, logs, and anomaly detection |
| **Security** | AWS WAF | Web application firewall |

#### Infrastructure as Code

The entire infrastructure is defined as code (Infrastructure as Code) using SST (Serverless Stack) version 3 with Pulumi backend, guaranteeing:

- **Declarative definition**: Infrastructure written in TypeScript for type safety and compile-time validation
- **Automated deployment**: Reproducible and versioned deployment process
- **Native multi-region**: Declarative configuration for simultaneous deployment across multiple regions
- **State management**: Pulumi engine for infrastructure state management and drift detection
- **Version control**: All infrastructure changes go through code review and CI/CD

This approach eliminates error-prone manual configurations and guarantees consistency between development, staging, and production environments.

### 1.3 Database and data persistence

#### Amazon DynamoDB

DynamoDB is the primary database for all transactional and operational data on the platform:

- **Model**: NoSQL with composite primary keys that include `workspaceId` for tenant isolation
- **Scaling**: on-demand capacity mode with automatic scaling based on load
- **Performance**: single-digit millisecond latency for read/write operations
- **Partitioning**: automatic for load distribution
- **Replication**: global tables for real-time multi-region synchronization

#### Cloudflare D1

Dedicated database alongside DynamoDB to fulfill specific application functions:

- **Usage**: indexing and complex queries
- **Integration**: alongside primary database to optimize specific operations

### 1.4 Multi-tenant model with data isolation

AWorld implements a multi-tenant architecture with rigorous logical isolation that guarantees complete data separation between different clients.

#### Hierarchical structure

```
Platform (AWorld)
└── Account (client/tenant)
    └── Workspace (environment: production, staging, dev)
        └── User (end user with specific roles)
```

#### Isolation mechanisms

**At database level (DynamoDB)**:
- **Tenant-scoped keys**: each record includes `workspaceId` as part of the primary key
- **Automatic query filtering**: queries are automatically filtered by workspace
- **Row-level isolation**: physical impossibility of accessing data from different workspaces in the same query

**At API Gateway level**:
- AWS Lambda Authorizer validates every request
- The JWT token contains the `workspaceId` claim critical for isolation
- Cross-workspace access blocked before business logic execution

**At Cognito level**:
- Shared user pool with workspace-isolated credentials
- Dedicated Cognito app client per workspace
- Workspace-scoped JWT tokens

> **⚠️ Critical security note**: The `workspaceId` in the JWT token is the fundamental mechanism for multi-tenant isolation. Each API request validates that the `workspaceId` in the token matches the workspace of the requested resources, preventing cross-tenant access at the API Gateway level before the request reaches the backend.

### 1.5 Multi-region distribution

To guarantee high availability and disaster recovery, the AWorld infrastructure is distributed across multiple AWS regions in active-active configuration.

#### Operating regions

- **Primary region**: `eu-west-1` (Ireland) - Europe production
- **Backup region**: `eu-north-1` (Stockholm) - disaster recovery
- **Data residency**: 100% of data maintained in EU data centers for GDPR compliance

#### Geographic load balancing

AWS Route 53 manages intelligent traffic routing:
- **Geolocation routing**: users are directed to the geographically closest region
- **Continuous health checks**: continuous monitoring of regional status
- **Automatic failover**: in case of regional failure, traffic is automatically diverted to the backup region
- **Latency-based routing**: automatic optimization for lower latency

### 1.6 Advantages of serverless architecture

Adopting a serverless architecture offers significant benefits in operational and reliability terms.

#### Automatic scalability
- AWS Lambda scales automatically based on request volume
- No manual provisioning of servers or capacity
- Transparent handling of unpredictable traffic spikes (e.g., corporate engagement campaigns)
- Additional instances activated in milliseconds

#### Reduced operational management
- Patching and updates managed automatically
- Zero downtime for infrastructure maintenance
- Technical team focus on feature development instead of server maintenance

#### Intrinsic resilience
- Integrated fault tolerance
- Automatic distribution across multiple availability zones
- Significant reduction in single point of failure risk


## 2. Security and cybersecurity

### 2.1 Data encryption

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

### 2.2 API protection

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

- **Aikido Security**: continuous security monitoring platform (source: ISMS security policies)
- **Automatic detection**: behavioral analysis of API traffic
- **Real-time alerting**: immediate notifications on suspicious activity
- **Incident response**: automatic activation of countermeasures (e.g., IP blocking, aggressive throttling)

#### Vulnerability management

Structured vulnerability management system:

- **Critical vulnerabilities**: remediation within ≤ 15 days from identification (source: ISMS KPI list)
- **High vulnerabilities**: remediation within ≤ 30 days from identification (source: ISMS KPI list)
- **Penetration testing**: semi-annual security tests conducted by third parties (source: ISMS security policies)
- **Continuous scanning**: continuous monitoring via Aikido Security

### 2.3 Authentication

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

### 2.4 Authorization

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

### 2.5 JWT token structure

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

### 2.6 Security incident management

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


## 3. Compliance and certifications

### 3.1 GDPR compliance

AWorld is designed with GDPR compliance integrated from the architecture.

#### Privacy by design and by default

Privacy is a fundamental architectural principle, integrated at every level of the platform:

- **Integrated principles**: privacy considered from architectural design
- **Data minimization**: collection of only strictly necessary personal data
- **Anonymization and pseudonymization**: techniques implemented to reduce sensitive data exposure
- **Safe defaults**: default configurations guarantee data protection

#### Data subject rights

Technical implementation for exercise of GDPR rights:

- **Right to erasure**: complete deletion of user data on request
- **Data portability**: data export in structured format (JSON)
- **Right of access**: complete query of personal data associated with user
- **Rectification**: modification of incorrect or incomplete personal data
- **Restriction of processing**: possibility to limit specific processing

#### Explicit consent

The platform implements mechanisms to guarantee that each personal data processing is based on informed consent:

- **Consent collection**: mechanisms for explicit consent collection for data processing
- **Granularity**: granular consent for different processing purposes
- **Revocation**: possibility to revoke consent at any time

### 3.2 Audit and traceability

The platform implements a complete audit logging system that guarantees traceability of all operations for compliance and security purposes.

#### AWS CloudTrail

The AWS CloudTrail service tracks all cloud infrastructure management operations:

- **Coverage**: all AWS API calls (infrastructure management)
- **Retention**: logs preserved for compliance and audit purposes
- **Immutability**: non-modifiable logs to guarantee audit trail integrity

#### Application logs

Application logs record all user operations to guarantee complete traceability:

- **Operation tracking**: every CRUD operation tracked
- **Standardized timestamps**: ISO 8601 in UTC for all events
- **Metadata**: user ID, workspace ID, IP, user agent for each operation
- **Configurable retention**: log retention based on client regulatory requirements

#### Audit trail

The system maintains an immutable trace of all critical events for security and compliance:

- **Tracked events**:
  - Authentication and authorization (login, logout, token refresh)
  - Configuration changes (creation/modification of missions, users, content)
  - Sensitive data access
  - Permission and role changes
  - Data exports and downloads

### 3.3 Data residency

AWorld guarantees data residency in European data centers to ensure compliance with GDPR jurisdictional requirements.

#### EU data centers

All platform data resides exclusively in data centers located in the European Union:

- **Regions**: eu-west-1 (Ireland), eu-north-1 (Stockholm)
- **Coverage**: 100% data in EU data centers (source: ISMS KPI list)
- **Guarantee**: data does not transit outside the configured region
- **Compliance**: compliance with GDPR requirements on extra-EU data transfer

#### Multi-region configuration

The platform offers flexibility in geographic data configuration to meet specific requirements:

- **Support**: possibility to configure specific regions for data residency
- **Flexibility**: dedicated deployments for specific jurisdictional requirements

#### Sub-processors

Sub-processor management is transparent and compliant with GDPR requirements:

- **Registry**: list of authorized and tracked sub-processors
- **Compliance**: all sub-processors GDPR compliant
- **Transparency**: DPA documentation available with sub-processors

### 3.4 Information Security Management System (ISMS)

#### ISO 27001:2022 compliance

AWorld has implemented an Information Security Management System (ISMS) compliant with the ISO/IEC 27001:2022 standard:

- **Implemented controls**: verified and operational ISO 27001 security controls
- **Statement of Applicability (SoA)**: document defining applicable controls
- **Internal audits**: annual verifications of effectiveness of implemented controls
- **Formal certification**: certification process in progress

#### Operational security controls

The ISMS includes operational controls verified and applied daily. In particular, for access control (source: ISMS access control policy):

- Mandatory MFA on all critical systems
- Password minimum 12 characters managed in secure vault (Bitwarden)
- Semi-annual access reviews for permission verification
- Mandatory endpoint encryption (FileVault)

The management system provides continuous improvement mechanisms:

- Annual internal audits
- Periodic risk assessment
- Control updates based on new threats

#### AWS Well-Architected Framework

The platform architecture follows best practices defined by the five pillars of the AWS Well-Architected Framework:

- **Security**: encryption, WAF, IAM policies, least privilege
- **Reliability**: multi-AZ, backup, disaster recovery
- **Performance efficiency**: caching, CDN, database optimization
- **Cost optimization**: serverless, auto-scaling, rightsizing
- **Operational excellence**: monitoring, alerting, automation

### 3.5 Contractual compliance

#### Data Processing Agreement (DPA)

For enterprise clients, AWorld makes formal contractual documentation available:

- **Availability**: DPA available for enterprise clients
- **Contents**: roles and responsibilities in personal data processing
- **Compliance**: alignment with GDPR Article 28 requirements

#### Service Level Agreement (SLA)

Formal guarantees on uptime and performance:

- **Guaranteed uptime**: ≥ 99.9% annual (source: ISMS SLA document)
- **Monitoring**: continuous monitoring via AWS CloudWatch Application Signals
- **Performance metrics**: API latency ≥ 99% requests < 1000ms (source: ISMS KPI list)
- **Support response times**:
  - P1 (Critical): 4 business hours
  - P2 (Standard): 1 business day
  - P1 Status Updates: every 2 hours (100% compliance)


## 4. Disaster recovery and business continuity

### 4.1 Resilience architecture

AWorld is designed to guarantee operational continuity even in disaster scenarios.

#### Active-active multi-region configuration

The infrastructure is geographically distributed to guarantee maximum resilience:

- **Simultaneous deployment**: services active simultaneously in multiple AWS regions
- **No single point of failure**: every component redundant
- **Automatic replication**: continuous synchronization between regions

#### Component distribution

Each architectural component is replicated to guarantee continuous availability:

- **Database**: DynamoDB global tables with real-time replication
- **Static files**: multi-data center synchronization
- **API and services**: distribution across multiple nodes per region
- **DNS**: Route 53 with health checks and automatic failover

### 4.2 Data replication

The data replication strategy guarantees continuous synchronization between regions and rapid recovery capability.

#### Amazon DynamoDB global tables

The primary database uses DynamoDB Global Tables technology for multi-region replication:

- **Replication**: real-time between AWS regions
- **Consistency**: eventual consistency for optimal performance
- **Latency**: replication lag typically < 1 second
- **Failover**: read/write possible on any region

#### Automatic backups

In addition to real-time replication, the system implements periodic backups for additional protection:

- **Frequency**: automatic backups managed by AWS
- **Point-in-time recovery (PITR)**: recovery at any time point in the last 35 days
- **Retention**: configurable based on client requirements

### 4.3 Recovery objectives

Formal disaster recovery objectives tested annually.

#### Recovery Time Objective (RTO)

The Recovery Time Objective defines the maximum time within which services must be restored:

- **Target**: ≤ 24 hours for critical function restoration (source: ISMS Business Continuity Plan)
- **Automatic failover**: traffic diversion via Route 53 without manual intervention
- **Backup region**: eu-north-1 (Stockholm) ready for activation

#### Recovery Point Objective (RPO)

The Recovery Point Objective defines the maximum amount of data that can be lost in case of disaster:

- **Target**: ≤ 1 hour maximum data loss in disaster scenarios (source: ISMS Business Continuity Plan)
- **Continuous replication**: databases replicated in real-time
- **Backup**: point-in-time recovery to minimize data loss

### 4.4 Proactive monitoring

A continuous monitoring system enables early detection of anomalies and automatic activation of countermeasures.

#### System metrics

AWS CloudWatch continuously monitors the status of all infrastructure resources. Tracked metrics include:

- Lambda CPU and memory usage
- API Gateway latency
- DynamoDB read/write capacity
- MemoryDB performance
- API error rate

#### Anomaly detection

Machine learning algorithms analyze usage patterns to identify anomalous behaviors:

- **Automatic anomaly detection**: machine learning for anomalous pattern identification
- **Event logging**: distributed event tracking infrastructure
- **Threshold alerts**: automatic notifications on threshold exceeding

#### Automatic countermeasures

Upon anomaly detection, the system automatically activates corrective measures:

- **Automatic failover**: to alternative region
- **Auto-scaling**: automatic resource increase in case of spikes
- **Access limitation**: throttling of suspicious users

### 4.5 Recovery procedures

#### Automatic DNS failover

The DNS failover process occurs automatically in case of regional failure, following these steps:

1. **Route 53 health checks**: continuous monitoring of regional endpoints
2. **Failure detection**: automatic identification of unavailable region
3. **Traffic diversion**: automatic DNS update to backup region
4. **DNS propagation**: typically completed within minutes
5. **Transparent restoration**: no perceived impact on users

#### User session continuity

User sessions remain active even during failover events thanks to stateless architecture:

- **JWT tokens**: independent of specific region, valid on all regions
- **Synchronized data**: real-time replication guarantees operational continuity
- **No interruption**: user sessions maintained during failover

#### Disaster recovery testing

Disaster recovery procedures are regularly tested to guarantee effectiveness:

- **Frequency**: periodic simulations of failure scenarios
- **Validation**: verification of actual RTO/RPO
- **Continuous improvement**: procedure refinement based on test results


## 5. Performance and scalability

### 5.1 Performance metrics

The platform guarantees specific performance objectives, continuously monitored and formalized in SLA.

#### Uptime

Service availability is contractually guaranteed and continuously monitored:

- **Target**: ≥ 99.9% annual (source: ISMS SLA document)
- **Monitoring**: AWS CloudWatch Application Signals
- **Calculation**: availability measured on monthly basis
- **Exclusions**: scheduled maintenance communicated with advance notice

#### API latency

API latency is optimized to guarantee fast response times:

- **Target**: ≥ 99% requests completed in < 1000ms (source: ISMS KPI list)
- **Monitoring**: p99 percentile tracked in CloudWatch
- **Optimization**: caching, query optimization, connection pooling

#### Response time

Response times vary based on the complexity of the requested operation:

- **Target p95**: < 2 seconds (source: ISMS KPI list)
- **Distribution**:
  - Simple operations (read): typically < 200ms
  - Complex operations (aggregate queries): < 2s

#### Error rate

The API error rate is maintained below rigorous thresholds:

- **Target**: < 0.5% (source: ISMS KPI list)
- **Monitoring**: error rate tracked per endpoint
- **Alerting**: automatic notifications on threshold exceeding

### 5.2 Automatic scalability

#### AWS Lambda

The serverless compute layer scales automatically without manual intervention:

- **Automatic scaling**: based on request volume
- **No manual provisioning**: capacity allocated automatically
- **Spike management**: transparent scaling during engagement campaigns
- **Rapid activation**: new instances in milliseconds

#### Amazon DynamoDB

The NoSQL database is configured in on-demand mode to dynamically adapt to load:

- **On-demand mode**: automatic read/write capacity scaling
- **Automatic partitioning**: load distribution for consistent performance
- **Unlimited throughput**: theoretically unlimited capacity (proportional costs)

### 5.3 Caching strategies and media storage

The system is optimized to guarantee high performance through intelligent caching and distributed storage of multimedia content.

#### AWS MemoryDB for Redis

In-memory database for features requiring ultra-fast data access:

- **Primary usage**: real-time leaderboard management
- **Performance**: sub-millisecond latency for read/write operations
- **Persistence**: guaranteed durability with snapshots and transaction log
- **Multi-AZ**: automatic replication for high availability

Benefits of using MemoryDB include:

- Real-time leaderboard updates without latency
- Support for atomic operations for ranking and scoring
- Horizontal scalability for high loads

#### Cloudflare R2 for media storage

Primary storage for multimedia content with integrated automatic caching:

- **Storage**: media content (images, videos, documents)
- **Automatic caching**: edge caching distributed globally
- **CloudFront integration**: automatic redundancy through CloudFront CDN
- **Optimized access**: content served from geographically close locations to users

This solution offers significant benefits:

- Reduced latency for multimedia content download
- Reduced load on application servers
- Optimized costs for storage and bandwidth
- Automatic geographic content distribution

### 5.4 Load balancing and traffic distribution

#### AWS Route 53

The DNS service manages intelligent traffic routing between regions:

- **Geolocation routing**: users directed to the closest region
- **Latency-based routing**: optimization for lower network latency
- **Continuous health checks**: regional endpoint status monitoring
- **Automatic failover**: traffic diversion in case of regional failure

#### AWS Lambda distribution

Computational load is automatically distributed between multiple instances:

- **Automatic balancing**: load distributed across multiple Lambda nodes
- **Fair distribution**: intelligent execution allocation
- **High concurrency management**: no bottleneck for traffic spikes

### 5.5 Capacity and limits

#### Configurable rate limiting

The system implements request rate controls to guarantee fairness and protection:

- **Per tenant**: workspace-specific throttling policies
- **Abuse prevention**: protection from excessive usage
- **Fair usage**: resource fairness guarantee in multi-tenant environment

#### Default API Gateway limits

Configurable on request for enterprise clients:
- **Request timeout**: 29 seconds (AWS API Gateway limit)
- **Payload size**: 6MB max per request
- **Throttling**: dynamic based on client plan

### 5.6 Idempotency and operation resilience

To guarantee resilience in retry scenarios and network instability, the platform implements native idempotency through AWS Lambda Powertools:

**AWS Lambda Powertools Idempotency**:
- **Persistence**: Dedicated DynamoDB table for idempotency key storage
- **Header support**: `X-Idempotency-Key` provided by client for critical operations
- **Auto-generation**: If header not provided, Powertools generates key automatically from body + path parameters
- **TTL management**: Keys expire automatically after completion with automatic cleanup
- **Response caching**: Original response cached and returned immediately for duplicate requests

**Middleware Integration**:

The idempotency middleware is automatically integrated into the pipeline of every write endpoint:

```
Request → CORS → Logger → M2M Delegation → Parser → Idempotency Check → Handler
                                                          ↓
                                                    DynamoDB Cache
                                                          ↓
                                        (if duplicate) → Return Cached Response
```

**Benefits**:
- **Network retry safety**: Client can retry POST/PUT/PATCH requests without risk of duplicates
- **Distributed system resilience**: Partial failure management in distributed systems
- **Audit compliance**: Every operation uniquely traced with idempotency key
- **Performance**: Duplicate requests resolve in ~10ms (DynamoDB read) vs full execution
- **Developer experience**: Transparent idempotency, no custom code necessary

**Use Cases**:
- Resource creation (missions, users, content)
- Financial operations (point assignment, virtual currency)
- Batch operations with possible retries
- Mobile apps with unstable connectivity


## 6. Access methods and integration

AWorld exposes functionality through REST API with dual-context architecture to separate administrative and end-user access.

### 6.1 REST API

#### Endpoint domains

The platform exposes two main domains for authentication and API:

- **Auth domain**: `https://auth.aworld.cloud`
- **API domain (current)**: `https://api.eu-west-1.aworld.cloud`
- **API domain (future)**: `https://api.aworld.cloud` (migration planned March 1, 2026)

> **Note**: During the transition period both domains will be functional.

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

### 6.2 Pre-provisioning and user access

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

### 6.3 Trigger access mode

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

### 6.4 Support for future protocols

The architecture is designed for future evolution with support for modern protocols like GraphQL.

#### GraphQL-ready architecture

Architecture designed to support GraphQL as additional API layer:

- **Greater data control**: client requests only necessary fields
- **Aggregation**: information from multiple sources in single query
- **Bandwidth reduction**: optimization for mobile clients
- **Timeline**: 2026-2027 product roadmap

### 6.5 Single sign-on (SSO) and SAML

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

### 6.6 Middleware stack and error handling

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
  "url": "https://api.eu-west-1.aworld.cloud/app/v1/missions",
  "docs": "https://docs.aworld.cloud/errors/auth/invalid_token"
}
```

**Idempotency Header Echo**:
- Response includes `X-Idempotency-Key` echoed back to client
- Client can verify that request was processed correctly
- Useful for debugging and troubleshooting distributed systems


## Appendix A: Technical glossary

### Architectural terms

**Active-active**: multi-region configuration where all regions are simultaneously operational.

**Multi-tenant**: architecture where multiple clients (tenants) share the same infrastructure with logical isolation.

**Serverless**: architectural model where the cloud provider automatically manages resource allocation without manual server provisioning.

**Workspace**: isolated environment for a client (production, staging, dev).

### Security terms

**ABAC (Attribute-Based Access Control)**: access control based on dynamic user attributes and context.

**JWT (JSON Web Token)**: standard for authentication/authorization tokens containing cryptographically signed claims.

**MFA (Multi-Factor Authentication)**: authentication requiring multiple forms of identity verification.

**OTP (One-Time Password)**: single-use password valid for single session or transaction.

**RBAC (Role-Based Access Control)**: access control based on predefined roles with static permissions.

**WAF (Web Application Firewall)**: firewall that inspects HTTP traffic to block web attacks.

### Compliance terms

**DPA (Data Processing Agreement)**: agreement defining roles and responsibilities in personal data processing.

**GDPR (General Data Protection Regulation)**: European regulation on personal data protection.

**ISMS (Information Security Management System)**: information security management system according to ISO 27001.

**Privacy by Design**: principle that integrates privacy from system design.

**RPO (Recovery Point Objective)**: maximum amount of data that can be lost in disaster scenario.

**RTO (Recovery Time Objective)**: maximum time to restore service after disaster.

### Operational terms

**Failover**: automatic process of switching to backup system in case of primary failure.

**Health check**: automatic service status monitoring for failure detection.

**Throttling**: request rate limitation to prevent abuse and guarantee fair usage.
