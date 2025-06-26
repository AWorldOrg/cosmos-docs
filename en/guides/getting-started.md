# Getting Started with AWorld

This guide will help you quickly set up and begin using the AWorld SaaS platform.

## Overview

AWorld is a multi-tenant SaaS platform that provides a suite of APIs across three contexts: App, Dashboard, and Portal. This guide will walk you through the initial setup and basic integration steps.

## Prerequisites

Before you begin, you'll need:

- A AWorld account (provided by your administrator or created through sign-up)
- Basic understanding of GraphQL (for API interactions)
- Development environment with your preferred language/framework

## Account and Workspace Setup

1. **Account Access**: You'll receive an invitation email with instructions to access your AWorld account.

2. **User Types**:
   - If you're a **Principal** (platform-level user), you'll have access to manage multiple accounts.
   - If you're a **User** (workspace-level user), you'll have access to a specific workspace within an account.

3. **Workspace Selection**: Once logged in, you'll be able to select your workspace if you have access to multiple workspaces.

## Authentication

AWorld uses AWS Cognito with a custom domain for authentication. For a complete guide, see [Authentication & Authorization](./authentication.md).

### Quick Authentication Overview

1. **Register and Sign In**:
   - Use the standard OAuth2 authentication flow
   - Upon successful authentication, you'll receive access and refresh tokens

2. **Using Tokens**:
   - Include the access token in all API requests as a Bearer token:
   
   ```
   Authorization: Bearer YOUR_ACCESS_TOKEN
   ```

   - Implement refresh token logic to obtain new access tokens when they expire

## API Basics

AWorld provides three API contexts:

- **App Context**: For user-facing functionality within a workspace
- **Dashboard Context**: For management and observability functionality within a workspace
- **Portal Context**: For platform-level operations across accounts and workspaces (principals only)

### Making Your First API Call

Here's a simple example of submitting a quiz answer using the App context API:

```javascript
async function submitQuizAnswer(quizId, answer, accessToken) {
  const mutation = `
    mutation SubmitQuiz($input: SubmitQuizInput!) {
      submitQuiz(input: $input) {
        quizId
        userId
        outcome
      }
    }
  `;

  const variables = {
    input: {
      quizId: quizId,
      answer: answer,
      context: "default"
    }
  };

  try {
    const response = await fetch('https://api.aworld.cloud/app/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({
        query: mutation,
        variables: variables
      })
    });

    const result = await response.json();
    
    if (result.errors) {
      console.error('GraphQL errors:', result.errors);
      throw new Error(result.errors[0].message);
    }
    
    return result.data.submitQuiz;
  } catch (error) {
    console.error('Error submitting quiz:', error);
    throw error;
  }
}
```

## Next Steps

After completing the initial setup, here are some recommended next steps:

1. **Explore API References**:
   - [App Context API Reference](../api-reference/app/README.md)
   - [Dashboard Context API Reference](../api-reference/dashboard/README.md)
   - [Portal Context API Reference](../api-reference/portal/README.md)

2. **Learn About Key Concepts**:
   - [Working with Workspaces](./workspaces.md)
   - [Understanding Multi-tenancy](./multi-tenancy.md)

3. **Integration Best Practices**:
   - Implement proper error handling for API calls
   - Set up token refresh logic to handle expiring access tokens
   - Use pagination for handling large datasets
   - Request only the fields you need in GraphQL queries

## Common Issues and Troubleshooting

### Authentication Issues

- **Invalid Tokens**: Ensure you're using a valid, non-expired access token
- **Permission Denied**: Verify that your user has the necessary permissions for the requested operation
- **Wrong Context**: Confirm you're using the correct API context for your operation

### API Usage

- **GraphQL Syntax**: Validate your GraphQL syntax before sending requests
- **Required Fields**: Ensure all required fields are included in your input parameters
- **Rate Limits**: While there are no rate limits in pre-alpha, be mindful of excessive API calls

## Support and Resources

- **Documentation**: Refer to this documentation site for detailed information
- **Support**: Contact your account administrator for platform-specific support
- **GraphQL Resources**: Visit [graphql.org](https://graphql.org/learn/) for GraphQL learning resources
