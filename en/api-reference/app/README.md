# App Context API Reference

This section documents the API endpoints available in the App context of the Cosmos platform.

## Introduction

The App context provides APIs for integrating with and extending applications built on the Cosmos platform. These APIs are designed for use in end-user applications and client-side interfaces.

## Authentication

All App context APIs require authentication. Requests must include a valid access token in the Authorization header:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

For information on obtaining access tokens, see the [Authentication Guide](../../guides/authentication.md).

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

### Caching

Queries (read-only operations) in the App context leverage an internal caching mechanism to improve performance. This means that repeated identical queries may return faster as they might be served from cache.

### Response Compression

To reduce payload size and improve transfer times, you can enable compression by including the following header in your requests:

```
Accept-Encoding: gzip
```

### Schema Introspection

GraphQL provides introspection capabilities that allow you to explore available operations, types, and fields. You can use standard GraphQL introspection queries to discover the schema details:

```graphql
query {
  __schema {
    types {
      name
      description
    }
  }
}
```

Many GraphQL clients (for example Postman) automatically provide introspection features, allowing you to browse the schema and available operations.

> **Note**: The Cosmos API is in pre-alpha stage and undergoes frequent updates. Schema introspection is a great way to discover the latest available operations.

## Pagination

List queries in Cosmos support pagination through a Connection pattern with the following structure:

```graphql
type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}
```

All operations that return paginated lists return a "Connection" that contains a list of items of the relevant type and an optional `nextToken` for requesting the next page.

Example query with pagination:

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

The pagination input typically follows this structure:

```graphql
input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

Example variables:

```json
{
  "input": {
    "limit": 10,
    "nextToken": "eyJsYXN0SXRlbUlkIjoiMTIzNDUiLCJsYXN0SXRlbVZhbHVlIjoidGVzdCJ9"
  }
}
```

### Pagination Guidelines

- You can specify an optional `limit` to control the number of items returned per page
- If no limit is provided, the system will use a default value
- To retrieve the next page, pass the `nextToken` from the previous response
- **Important**: A `nextToken` is only valid when used with the same `limit` that was used in the original request. You should not mix tokens returned from calls with different limit values

## Rate Limiting

At pre-alpha stage, there are not rate limits applied yet.

## Best Practices

1. **Use GraphQL variables** for dynamic values rather than string interpolation
2. **Request only the fields you need** to minimize response size and processing time
3. **Implement error handling** to gracefully handle different error scenarios
4. **Use pagination** for large result sets to improve performance
5. **Cache responses** where appropriate to reduce API calls

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
