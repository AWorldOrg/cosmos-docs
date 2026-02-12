## What is Multi-tenancy?

Multi-tenancy is a software architecture in which a single instance of software serves multiple customers or "tenants." Each tenant's data and configuration remains isolated from other tenants, even though they share the underlying infrastructure and application code.

In the AWorld platform, an **Account** represents a tenant – typically an organization or company using the platform.

## Multi-tenant Architecture in AWorld

The AWorld platform implements a hierarchical multi-tenant architecture:

```
Platform
└── Account (Tenant)
    └── Workspace
        └── User
```

### Key Components

- **Platform**: The top-level AWorld system that hosts all accounts
- **Account**: A tenant with its own isolated data and configuration
- **Workspace**: An environment within an account (e.g., development, staging, production)
- **User**: A workspace-level user with specific permissions
- **Principal**: A platform-level user that can operate across accounts and workspaces

## Tenant Isolation

The AWorld platform ensures tenant isolation at multiple levels:

### Data Isolation

Each account's data is logically isolated from other accounts. This isolation ensures that:

- One tenant cannot access another tenant's data
- Issues in one tenant's environment don't affect others
- Each tenant can have custom configurations

### Authentication and Authorization

The platform uses AWS Cognito with a custom domain for authentication, providing:

- Tenant-specific authentication flows
- User management within each account
- Role-based access control at both the account and workspace levels

### API Access

All API calls are authenticated and scoped to the appropriate tenant context:

- App context APIs operate within a specific workspace, offering user facing functionalities
- Dashboard context APIs operate within a specific workspace, offering management and observability functionalities
- Portal context APIs can operate across accounts and workspaces (for principals only)

## Benefits of Multi-tenancy

The multi-tenant architecture of AWorld provides several advantages:

### For Service Providers

- **Operational Efficiency**: Managing a single software instance is more efficient than managing separate instances for each customer
- **Resource Optimization**: Shared infrastructure leads to better resource utilization
- **Simplified Maintenance**: Updates and improvements benefit all tenants simultaneously
- **Cost Effectiveness**: Lower operational costs compared to single-tenant deployments

### For Tenants (Accounts)

- **Rapid Onboarding**: Quick setup without complex infrastructure provisioning
- **Automatic Updates**: Always access the latest features and security patches
- **Scalability**: Infrastructure scales with usage needs
- **Workspace Flexibility**: Ability to create multiple isolated environments within an account

## Security Considerations

While multi-tenancy offers many benefits, it also requires careful security implementation:

- **Authentication**: Robust identity verification to ensure users only access their authorized accounts
- **Authorization**: Fine-grained permission controls to limit access within accounts
- **Data Isolation**: Strong boundaries between tenant data
- **Logging and Auditing**: Comprehensive activity tracking to detect unauthorized access attempts

## Multi-tenant API Usage

When interacting with AWorld APIs, the tenant context is established through authentication:

1. **User Authentication**: Upon login, the user is associated with a specific workspace and account
2. **Access Token**: The JWT token contains claims about the user's identity and permitted tenant scopes
3. **API Requests**: All API calls include the access token, which determines the tenant context

## Best Practices for Multi-tenant Operation

### For Platform Administrators

- Regularly audit tenant isolation mechanisms
- Monitor for potential cross-tenant access vulnerabilities
- Implement rate limiting to prevent tenant resource monopolization
- Ensure proper backup and disaster recovery procedures for all tenants

### For Account Administrators

- Implement a clear workspace strategy for different environments
- Review user access permissions regularly
- Use separate workspaces for development and production
- Follow the principle of least privilege when assigning roles