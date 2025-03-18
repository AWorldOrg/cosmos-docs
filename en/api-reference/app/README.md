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

**Endpoint:** `https://api.aworld.cloud/app/graphql`

### REST APIs

REST APIs will have feature parity with GraphQL APIs but are not published yet:

**Future Base URL:** `https://api.aworld.cloud/app`

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

## Error Handling

GraphQL responses may include errors within the `errors` array:

```json
{
  "errors": [
    {
      "message": "Not authorized to access this resource",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["me"],
      "extensions": {
        "code": "FORBIDDEN"
      }
    }
  ],
  "data": null
}
```

Common error codes:

- `UNAUTHENTICATED`: Missing or invalid authentication
- `FORBIDDEN`: Authentication valid but insufficient permissions
- `BAD_USER_INPUT`: Invalid input parameters
- `NOT_FOUND`: Requested resource not found

## Pagination

List queries typically support pagination parameters:

```graphql
query GetPaginatedItems($first: Int, $after: String) {
  items(first: $first, after: $after) {
    edges {
      node {
        id
        name
      }
      cursor
    }
    pageInfo {
      hasNextPage
      endCursor
    }
  }
}
```

Example variables:

```json
{
  "first": 10,
  "after": "cursor_from_previous_page"
}
```

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

  const response = await fetch('https://api.aworld.cloud/app/graphql', {
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
