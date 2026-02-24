### GDPR compliance

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

### Audit and traceability

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

### Data residency

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

### Information Security Management System (ISMS)

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

### Contractual compliance

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
