# Quizzes

> **Important**: This detailed documentation is provided for demonstration purposes. Always refer to the GraphQL schema (using introspection) for the most up-to-date API documentation. The schemas evolve over time, and introspection will always provide the current definition.

Quizzes are interactive assessment units used throughout the AWorld platform to engage users and evaluate knowledge. This document provides comprehensive information about the Quiz entity, its properties, and how it's used across different contexts.

## Overview

Quizzes in the AWorld platform serve as knowledge assessment tools that can be embedded in various content types. They support multiple difficulty levels, internationalization through translations, and detailed outcome tracking.

## Data Model

### Core Fields

| Field             | Type              | Description                                        | Required   |
| ----------------- | ----------------- | -------------------------------------------------- | ---------- |
| `quizId`          | ID                | Unique identifier for the quiz                     | Yes        |
| `difficulty`      | QuizDifficulty    | Difficulty level: EASY, MEDIUM, or HARD            | Yes        |
| `answer`          | QuizAnswer        | Correct answer option: opt1, opt2, opt3, or opt4   | Yes        |
| `syncWithCatalog` | Boolean           | Whether the quiz syncs with the catalog            | No         |
| `origin`          | QuizOrigin        | Source of the quiz: CATALOG or CUSTOM              | Yes        |
| `placement`       | QuizPlacement     | Where the quiz appears: STANDALONE, STORY, or NEWS | Yes        |
| `quizCatalogId`   | ID                | Reference to the catalog quiz if applicable        | Yes        |
| `translations`    | [QuizTranslation] | List of translations for different languages       | Yes        |
| `createdAt`       | AWSDateTime       | Timestamp when the quiz was created                | Yes (auto) |
| `updatedAt`       | AWSDateTime       | Timestamp when the quiz was last updated           | Yes (auto) |

### QuizTranslation

| Field         | Type        | Description                                     | Required   |
| ------------- | ----------- | ----------------------------------------------- | ---------- |
| `quizId`      | ID          | Reference to the parent quiz                    | Yes        |
| `lang`        | String      | Language code (e.g., "en", "it")                | Yes        |
| `opt1`        | String      | First answer option                             | Yes        |
| `opt2`        | String      | Second answer option                            | Yes        |
| `opt3`        | String      | Third answer option                             | No         |
| `opt4`        | String      | Fourth answer option                            | No         |
| `question`    | String      | The quiz question text                          | Yes        |
| `explanation` | String      | Explanation of the correct answer               | No         |
| `createdAt`   | AWSDateTime | Timestamp when the translation was created      | Yes (auto) |
| `updatedAt`   | AWSDateTime | Timestamp when the translation was last updated | Yes (auto) |

### GraphQL Schema

```graphql
enum QuizDifficulty {
  EASY
  MEDIUM
  HARD
}

enum QuizAnswer {
  opt1
  opt2
  opt3
  opt4
}

enum QuizOrigin {
  CATALOG
  CUSTOM
}

enum QuizPlacement {
  STANDALONE
  STORY
  NEWS
}

enum QuizOutcome {
  SUCCESS
  FAIL
}

type Quiz {
  quizId: ID!
  difficulty: QuizDifficulty!
  answer: QuizAnswer!
  syncWithCatalog: Boolean
  origin: QuizOrigin!
  placement: QuizPlacement!
  quizCatalogId: ID!
  translations: [QuizTranslation!]!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}

type QuizTranslation {
  quizId: ID!
  lang: String!
  opt1: String!
  opt2: String!
  opt3: String
  opt4: String
  question: String!
  explanation: String
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type QuizLog {
  quizId: ID!
  userId: ID!
  lang: String!
  difficulty: QuizDifficulty!
  answer: QuizAnswer!
  outcome: QuizOutcome!
  context: String!
  createdAt: AWSDateTime!
}
```

## Lifecycle

### Creation

Quizzes can be created in two ways:
1. **Custom creation** (origin: CUSTOM) - Created directly through the Dashboard API
2. **Catalog synchronization** (origin: CATALOG) - Imported from the quiz catalog with optional customization

When creating a quiz, you must provide at least one translation. The primary language should match the workspace's default language.

### Updates

Quizzes can be updated through the Dashboard API. Updates to quizzes include:
- Modifying quiz properties (difficulty, placement, etc.)
- Adding, updating, or removing translations
- Changing the correct answer

### Deletion

While quizzes can be logically deleted (hidden from users), they are typically preserved for analytics and tracking purposes.

## Cross-Context Usage

### App Context

In the App context, quizzes are primarily consumed by end users. See [App Context API Reference](../app/README.md#available-mutations) for details.

Key operations:
- **Submitting answers** (`submitQuiz` mutation)
- **Listing available quizzes** (`listQuizzes` query)

### Dashboard Context

In the Dashboard context, quizzes are managed by administrators. See [Dashboard Context API Reference](../dashboard/README.md#common-queries) for details.

Key operations:
- **Creating quizzes** (`createQuiz` mutation)
- **Updating quizzes** (`updateQuiz` mutation)
- **Archiving quizzes** (`archiveQuiz` mutation)
- **Listing and filtering quizzes** (`quizzes` query)

## Special Considerations

### Internationalization

- Each quiz must have at least one translation
- The quiz question and at least two answer options are required for each translation
- Best practice is to provide translations for all languages supported in your workspace
- Consistent terminology should be maintained across translations

### Quiz Difficulty

The difficulty level affects:
- User experience expectations
- Analytics and reporting
- Recommendation algorithms
- Rewards

Choose difficulty levels consistently based on:
- Complexity of the question
- Number of viable answer options
- Domain knowledge required

### Quiz Placement

The placement type determines where and how the quiz appears:
- **STANDALONE**: Independent quizzes accessible directly
- **STORY**: Quizzes embedded within story content
- **NEWS**: Quizzes associated with news articles

Each placement type may have different UX considerations and integration requirements.

## Common Patterns

### Quiz Submission Flow

A typical quiz submission flow includes:
1. Fetching quiz details
2. Displaying question and options to user
3. Collecting user answer
4. Submitting user response via API
5. Showing outcome and explanation
6. Recording analytics

### Localized Quiz Delivery

To deliver quizzes in the user's preferred language:
1. Retrieve user language preference
2. Query quizzes with matching translation
3. Fall back to workspace default language if no match
4. Display translated question and options

## Pitfalls to Avoid

### Common Mistakes

1. **Missing translations**: Always provide translations for all supported languages
2. **Inconsistent difficulty**: Maintain consistent criteria for difficulty levels
3. **Ambiguous questions**: Ensure questions have clear, unambiguous answers
4. **Insufficient answer options**: Provide enough options for meaningful assessment
5. **Missing explanations**: Always include explanations for better user experience

## Examples

### Creating a Quiz

```graphql
mutation CreateQuiz($input: CreateQuizInput!) {
  createQuiz(input: $input) {
    quizId
    difficulty
    answer
    origin
    placement
    translations {
      lang
      question
      opt1
      opt2
      opt3
      opt4
      explanation
    }
  }
}
```

Variables:
```json
{
  "input": {
    "difficulty": "MEDIUM",
    "answer": "opt2",
    "origin": "CUSTOM",
    "placement": "STORY",
    "translations": [
      {
        "lang": "en",
        "question": "What is the capital of Italy?",
        "opt1": "Milan",
        "opt2": "Rome",
        "opt3": "Florence",
        "opt4": "Venice",
        "explanation": "Rome is the capital city of Italy."
      },
      {
        "lang": "it",
        "question": "Qual è la capitale d'Italia?",
        "opt1": "Milano",
        "opt2": "Roma",
        "opt3": "Firenze",
        "opt4": "Venezia",
        "explanation": "Roma è la capitale d'Italia."
      }
    ]
  }
}
```

### Context Usage in Quiz Submission

The `context` parameter in quiz submissions serves an important purpose:

```graphql
# Input for submitting a quiz answer.
input SubmitQuizInput {
  # ID of the quiz being answered.
  quizId: ID!
  # User's selected answer.
  answer: QuizAnswer!
  # Context in which the quiz have been answered. Users can answer a quiz only once per context. 
  # Using context creatively, complex logic can be built (for example, using a date, a month, a custom context, etc)
  context: String
}
```

Users can answer a quiz only once per unique context. This provides flexibility for implementing various quiz scenarios:
- Use date-based contexts (e.g., "2025-03-18") to allow daily quiz attempts
- Use location contexts (e.g., "homepage", "story-123") for different placements
- Use sequential contexts (e.g., "level-1", "level-2") for progression tracking
- Use custom contexts for specialized workflows

### Submitting a Quiz Answer

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
      context: context  // Use strategically for replay control
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

## Related Entities

- **QuizLog** - Records of quiz attempts by users
- **User** - The entity that attempts quizzes
- **QuizCatalog** - Source of standard quizzes that can be synced

## Additional Resources

- [App Context API](../app/README.md)
- [Dashboard Context API](../dashboard/README.md)
- [Quiz Best Practices Guide](#) (coming soon)
- [Quiz Analytics Guide](#) (coming soon)
