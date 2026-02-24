### Architecture overview

AWorld implements a fully serverless cloud-native architecture on Amazon Web Services (AWS), designed to guarantee unlimited scalability and high availability. The architecture is organized in functional layers that separate responsibilities and facilitate platform evolution:

- **Account & user layer**: identity management, permissions, authentication (AWS Cognito), and server-to-server integration
- **Gamification layer**: core engine for engagement mechanics (missions, levels, leaderboards, badges, points)
- **Catalog layer**: distribution and organized management of training content

The multi-tenant architecture guarantees rigorous data isolation between clients, with each workspace operating in complete logical independence while sharing the underlying physical infrastructure for operational efficiency.

### Technology stack

The platform is based on AWS services, which guarantee high standards of security, reliability, and reduced infrastructure maintenance requirements.

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

### Database and data persistence

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

### Multi-tenant model with data isolation

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

### Multi-region distribution

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

### Advantages of serverless architecture

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
