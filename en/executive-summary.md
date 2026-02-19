# AWorld Platform

**Executive Summary - Architecture, security, and reliability**

---

## 1. Product and architecture

### 1.1 Cloud infrastructure

AWorld's entire infrastructure is cloud-native and hosted on Amazon Web Services (AWS). The choice of a fully serverless approach eliminates manual management of physical servers or virtual machines, dynamically allocating computational resources based on demand.

Key infrastructure components include:

**Computing**: utilization of AWS Lambda and API Gateway for efficient request management and automatic scalability that adapts to traffic spikes without service interruptions.

**Database**: adoption of Amazon DynamoDB to manage data volumes with low latency and ensure rigorous data segregation. The stack also incorporates a dedicated Cloudflare D1 database to enable indexing and fulfill certain application functions.

**Performance**: implementation of distributed caching strategies and load balancing to optimize response times and ensure business continuity.

The adopted model guarantees high performance and intrinsic resilience: the infrastructure is distributed across multiple AWS regions with active Disaster Recovery strategies to ensure operational continuity even in case of localized failures.

### 1.2 Layered architecture

The system is organized into distinct logical layers that separate responsibilities, facilitating platform maintenance and evolution:

**Account & User Layer**: responsible for secure identity management, permissions, and authentication (managed via AWS Cognito and JWT). It natively supports multi-tenant architectures.

**Gamification Layer**: the heart of the engagement engine. It manages game mechanics such as leaderboards, levels, badges, and progress, enabling the transformation of user activities into measurable results.

**Catalog Layer**: manages the distribution of learning content, allowing companies to use both AWorld's validated catalog and upload their own proprietary content.

On the user side, the ecosystem consists of a Web App for resources (accessible from mobile and desktop) and a Backoffice for administration, path management and assignment, and data analysis.

### 1.3 Multi-tenancy and scalability

The system implements an advanced multi-tenant model that guarantees complete data isolation between different organizations. Every API request is automatically confined to the customer's data perimeter through composite primary keys on DynamoDB, physically preventing cross-access to other tenants' data.

The serverless architecture enables automatic scalability that dynamically adapts to traffic volumes. During usage spikes, the system activates additional instances in milliseconds without manual provisioning, ensuring consistent performance even under high load conditions. This intrinsic elasticity eliminates fixed costs associated with traditional infrastructures, optimizing spending based on actual usage.

## 2. Security, compliance, and data management

### 2.1 Security and protection

Security is integrated into every level of the architecture (Privacy by Design), with particular attention to protecting corporate data in enterprise contexts.

**Multi-tenancy and segregation**: the system implements a rigorous logical isolation model. Every API request is automatically confined to the customer's data perimeter through composite primary keys on DynamoDB, physically preventing cross-access to data.

**Encryption**: all data is encrypted both in transit (TLS 1.2/1.3) and at rest (AES-256), using secure algorithms to prevent unauthorized access. Encryption key management is centralized and automated through AWS, reducing exposure risks.

**Access control (RBAC/ABAC)**: permission management is based on roles (Role-Based Access Control) with the ability to evolve toward attribute-based controls (ABAC) for even greater granularity. API authentication is managed through AWS Lambda Authorizer, which validates every single request in real-time by verifying token authenticity and associated permissions.

**Active protection**: the platform is protected by a Web Application Firewall (WAF) and threat detection systems that monitor traffic to block abuse attempts, DDoS attacks, or injection. Rate limiting policies prevent overloads and ensure fair resource distribution among different tenants.

### 2.2 GDPR compliance and certifications

The platform is designed with a Privacy by Design approach to ensure full GDPR compliance. The system implements data minimization principles, collecting exclusively personal data strictly necessary for service operation, and applies pseudonymization techniques to reduce sensitive information exposure.

Users have full control over their personal data: the platform natively supports all data subject rights provided by GDPR, including the right to data portability (export in structured format), the right to erasure (complete deletion), and the right of access (complete query of personal data).

Every operation is tracked through detailed audit logging, with standardized timestamps and immutable logs that ensure activity transparency and support compliance verification. All data resides 100% in European data centers (primary region eu-west-1, Ireland), ensuring compliance with data residency and data sovereignty requirements.

The organization has implemented an Information Security Management System (ISMS) compliant with ISO 27001:2022 standard, with controls verified through annual internal audits. Formal certification is currently in the process of being obtained.

### 2.3 Authentication and authorization

The platform adopts modern and secure authentication mechanisms. For end users, the system implements passwordless authentication based on One-Time Password via email (EMAIL_OTP), eliminating risks associated with managing permanent credentials and simplifying the user experience.

For machine-to-machine (M2M) integrations with corporate systems, the platform supports the OAuth2 Client Credentials standard, allowing customer backends to interact with APIs securely and automatically.

Identity management is handled through AWS Cognito, which provides JWT (JSON Web Token) tokens with workspace-scoped claims to ensure multi-tenant isolation at the authorization level. Access tokens have a validity of 1 hour, while refresh tokens remain valid for 30 days, balancing security and usability. Every API request is validated in real-time by a Lambda Authorizer that verifies token authenticity and associated permissions.

## 3. Reliability and operational continuity

### 3.1 Disaster Recovery and business continuity

To ensure operational continuity even in critical scenarios, AWorld implements an active-active architecture distributed across multiple AWS regions. The primary configuration resides in eu-west-1 (Ireland), with automatic replication to eu-north-1 (Stockholm) that keeps data and services synchronized in real-time.

In case of localized failure or region unavailability, the system automatically activates failover procedures through AWS Route 53, diverting traffic to the functioning instance without perceptible interruption for end users. This approach guarantees rigorous recovery objectives: Recovery Time Objective (RTO) less than or equal to 24 hours and Recovery Point Objective (RPO) less than or equal to 1 hour, ensuring that in case of disaster, data loss is minimal and service restoration occurs quickly.

The system is equipped with continuous proactive monitoring that constantly analyzes usage metrics and detects anomalies in real-time. In case of performance degradation or suspicious behavior, countermeasures are automatically activated to preserve service stability and prevent interruptions.

### 3.2 Performance and SLA

The platform guarantees high reliability standards with an annual uptime greater than or equal to 99.9%, continuously monitored through AWS CloudWatch Application Signals. API performance is optimized to respond quickly: at least 99% of requests are completed in less than 1000 milliseconds, with a 95th percentile response time of less than 2 seconds even under load.

The error rate is maintained below 0.5%, ensuring service stability and predictability. In case of anomalies, the technical support system is structured to respond promptly: critical incidents (P1) are handled within 4 business hours, while standard requests (P2) receive a response within 1 business day.

Real-time monitoring and proactive metric analysis enable identification of potential problems before they impact users, ensuring a smooth and reliable user experience for all enterprise customers.

---

**Version**: 1.0
**Date**: February 2026
**Company**: AWorld S.r.l. Società Benefit
