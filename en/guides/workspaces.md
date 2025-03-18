# Working with Workspaces

This guide explains the concept of workspaces in the Cosmos platform and how to effectively manage them.

## What is a Workspace?

A workspace is an isolated environment within an account that provides a dedicated space for different stages of your application's lifecycle or for different teams within your organization. Each account can have multiple workspaces, allowing for organized resource management and access control.

## Workspace Hierarchy

In the Cosmos platform, the organizational hierarchy is:

1. **Platform**: The top-level Cosmos platform
2. **Account**: A tenant in the multi-tenant architecture
3. **Workspace**: An isolated environment within an account
4. **Resources**: Services, configurations, and data within a workspace

## Common Workspace Types

While you can organize workspaces according to your needs, common configurations include:

- **Development**: For building and testing new features
- **Staging**: For pre-production testing and quality assurance
- **Production**: For live applications serving end-users

Alternatively, you might create workspaces for different:

- Teams within your organization
- Client projects or business units
- Application types or services

## Workspace Resources

Each workspace operates as an isolated environment with its own:

- **Users**: Workspace-level users with specific roles and permissions
- **Configuration**: Settings specific to the workspace
- **Resources**: API keys, services, and data
- **Logs and Metrics**: Operational data specific to the workspace

## Workspace Permissions

Access to workspaces is controlled through a permission system:

- **Principal-level users** can access and manage multiple accounts and workspaces
- **Workspace administrators** can manage a specific workspace and its users
- **Workspace users** have access to resources within their assigned workspace, based on their roles

## Best Practices

### Workspace Naming Conventions

Establish a consistent naming convention for workspaces to make them easily identifiable:

- Include the purpose (e.g., "dev", "staging", "prod")
- Consider including team or project identifiers
- Use consistent patterns (e.g., "project-environment")

### Resource Isolation

- Keep development and production workspaces completely separate
- Avoid sharing sensitive credentials between workspaces
- Implement different security policies based on the workspace purpose

### User Access Management

- Regularly audit user access to workspaces
- Limit production workspace access to essential personnel
- Create temporary workspaces for contractors or temporary projects

### Workspace Lifecycle

- Clean up or archive unused workspaces
- Document the purpose and ownership of each workspace

## Workspace Data

Data within a workspace is logically isolated from other workspaces by default. This provides several advantages:

- **Security**: Data breaches in one workspace don't affect others
- **Organization**: Clearer organization of data by environment or purpose
- **Testing**: Ability to test with realistic data without affecting production
- **Compliance**: Easier to implement data residency or compliance requirements

## Example Workspace Configuration

A typical organization might use the following workspace configuration:

- **Development Workspace**: For engineers to build and test features
- **QA Workspace**: For quality assurance testing
- **Staging Workspace**: For final pre-production verification
- **Production Workspace**: For the live environment used by customers

## Related Topics

- [Understanding Multi-tenancy](./multi-tenancy.md)
- [Authentication & Authorization](./authentication.md)
