# App Context API Reference

This section documents the API endpoints available in the App context of the Cosmos platform.

## Introduction

The App context provides APIs for integrating with and extending applications built on the Cosmos platform. These APIs are designed for use in end-user applications and client-side interfaces.

## Authentication

The App context uses the common authentication mechanisms described in [Common API Features](../common-features.md#authentication-basics).

### M2M Implementation Details

For App context APIs that require "user level" access in machine-to-machine (M2M) flows, you must include the userId of the user to impersonate in a header with every call:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

This allows your service to perform actions on behalf of specific users while using client credentials for authentication.

## API Endpoints

### GraphQL API

The primary API for the App context is a GraphQL API:

**Current Endpoint:** `https://v1.gql.app.aworld.cloud/graphql`

> **Note**: These endpoints are currently exposing internal APIs directly to customers. In the future, all APIs will be accessible through a single reverse proxy, and these endpoints will change.

### API Versioning

- **GraphQL**: GraphQL APIs typically use a rolling updates approach without formal versioning until breaking changes occurs. This allows the API to evolve while maintaining backward compatibility. During this pre-alpha stage, more significant changes may occur, but once stable, changes will follow the rolling approach.

- **REST**: REST APIs (when published) will use explicit versioning (e.g., v1, v2). The version numbers will be aligned with GraphQL whenever REST requires updates.

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** To be determined after reverse proxy implementation

## GraphQL Schema

The App context GraphQL API provides the following main types of operations:

1. **Queries**: For retrieving data
2. **Mutations**: For creating, updating, or deleting data

### User Context

When authenticated, your API requests operate within the context of:

- The authenticated **User**
- The **Workspace** associated with the user
- The **Account** associated with the workspace

## GraphQL Schema Details

The App context GraphQL API includes the following components:

### Scalar Types

- `AWSDateTime`, `AWSDate`, `AWSTime`, `AWSTimestamp`
- `AWSEmail`, `AWSJSON`, `AWSURL`, `AWSPhone`, `AWSIPAddress`
- `Long`

### Interfaces

- `Node`: Base interface with creation and update timestamps
- `Connection`: Interface for paginated collections of items

### Enums

- `QuizDifficulty`: `EASY`, `MEDIUM`, `HARD`
- `QuizAnswer`: `opt1`, `opt2`, `opt3`, `opt4`
- `QuizOrigin`: `CATALOG`, `CUSTOM`
- `QuizPlacement`: `STANDALONE`, `STORY`, `NEWS`
- `QuizOutcome`: `SUCCESS`, `FAIL`

### Types

- `Quiz`: Represents a quiz with its properties
- `QuizConnection`: Paginated collection of quizzes
- `QuizTranslation`: Translations for a quiz (questions, options, explanations)
- `QuizLog`: Record of a quiz attempt by a user

## Available Mutations

### Submit Quiz

Submit a user's answer to a quiz:

```graphql
mutation SubmitQuiz($input: SubmitQuizInput!) {
  submitQuiz(input: $input) {
    quizId
    userId
    lang
    difficulty
    answer
    outcome
    context
  }
}
```

Example variables:

```json
{
  "input": {
    "quizId": "quiz-123",
    "answer": "opt2",
    "context": "default"
  }
}
```

## API Features

The App context implements the common API features described in [Common API Features](../common-features.md). Please refer to that document for detailed information about:

- [Caching](../common-features.md#caching)
- [Idempotency](../common-features.md#idempotency)
- [Response Compression](../common-features.md#response-compression)
- [Schema Introspection](../common-features.md#schema-introspection)

For the App context, idempotency is particularly important when creating or updating user data. For example, if you attempt to create the same user twice with concurrent requests or within the 5-minute idempotency window, only the first API call would succeed. Other calls would return the same payload with the added idempotency header.

## Pagination

The App context follows the standard pagination approach described in [Common API Features](../common-features.md#pagination).

For App-specific resources, the pagination pattern is implemented as follows:

```graphql
type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}
```

Example query for listing quizzes with pagination:

```graphql
query ListQuizzes($input: ListQuizzesInput) {
  listQuizzes(input: $input) {
    items {
      quizId
      difficulty
      answer
      placement
      createdAt
    }
    nextToken
  }
}
```

With input structure:

```graphql
input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

For pagination guidelines and best practices, refer to the [Common API Features](../common-features.md#pagination-guidelines) documentation.

## Rate Limiting

Please refer to the [Common API Features](../common-features.md#rate-limiting) documentation for information about rate limiting.


## Example Integration

Here's an example of integrating with the App context API in a JavaScript application to submit a quiz answer:

```javascript
async function submitQuizAnswer(quizId, userAnswer, context = "default") {
  const mutation = `
    mutation SubmitQuiz($input: SubmitQuizInput!) {
      submitQuiz(input: $input) {
        quizId
        userId
        lang
        difficulty
        answer
        outcome
        context
      }
    }
  `;

  const variables = {
    input: {
      quizId: quizId,
      answer: userAnswer,
      context: context
    }
  };

  const response = await fetch('https://v1.gql.app.aworld.cloud/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
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
}
```

## Additional Resources

- [GraphQL Documentation](https://graphql.org/learn/)
- [App Context Schema Explorer](#) (requires authentication)
- [API Changelog](#) (requires authentication)
