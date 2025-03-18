# Riferimento API Contesto App

Questa sezione documenta gli endpoint API disponibili nel contesto App della piattaforma Cosmos.

## Introduzione

Il contesto App fornisce API per l'integrazione e l'estensione delle applicazioni costruite sulla piattaforma Cosmos. Queste API sono progettate per l'uso in applicazioni per utenti finali e interfacce lato client.

## Autenticazione

Il contesto App utilizza i meccanismi di autenticazione comuni descritti nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md#nozioni-di-base-sullautenticazione).

### Dettagli Implementazione M2M

Per le API del contesto App che richiedono accesso a "livello utente" nei flussi machine-to-machine (M2M), è necessario includere l'userId dell'utente da impersonare in un header con ogni chiamata:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

Questo consente al tuo servizio di eseguire azioni per conto di specifici utenti utilizzando client credentials per l'autenticazione.

## Endpoint API

### API GraphQL

L'API principale per il contesto App è un'API GraphQL:

**Endpoint Attuale:** `https://v1.gql.app.aworld.cloud/graphql`

> **Nota**: Questi endpoint stanno attualmente esponendo API interne direttamente ai clienti. In futuro, tutte le API saranno accessibili attraverso un singolo reverse proxy, e questi endpoint cambieranno.

### Versionamento API

- **GraphQL**: Le API GraphQL tipicamente utilizzano un approccio di aggiornamenti continui (rolling updates) senza un versionamento formale fino a quando non si verificano cambiamenti incompatibili. Questo permette all'API di evolversi mantenendo la compatibilità all'indietro. Durante questa fase pre-alpha, potrebbero verificarsi cambiamenti più significativi, ma una volta stabile, i cambiamenti seguiranno l'approccio rolling.

- **REST**: Le API REST (quando saranno pubblicate) utilizzeranno un versionamento esplicito (es. v1, v2). I numeri di versione saranno allineati con GraphQL ogni volta che REST richiederà aggiornamenti.

### API REST

Le API REST avranno parità di funzionalità con le API GraphQL ma non sono ancora pubblicate:

**Futuro URL Base:** TBD

## Schema GraphQL

L'API GraphQL del contesto App fornisce i seguenti tipi principali di operazioni:

1. **Query**: Per recuperare dati
2. **Mutation**: Per creare, aggiornare o eliminare dati

### Contesto Utente

Quando autenticato, le tue richieste API operano nel contesto di:

- L'**User** autenticato
- Il **Workspace** associato all'utente
- L'**Account** associato al workspace

## Dettagli Schema GraphQL

L'API GraphQL del contesto App include i seguenti componenti:

### Tipi Scalari

- `AWSDateTime`, `AWSDate`, `AWSTime`, `AWSTimestamp`
- `AWSEmail`, `AWSJSON`, `AWSURL`, `AWSPhone`, `AWSIPAddress`
- `Long`

### Interfacce

- `Node`: Interfaccia di base con timestamp di creazione e aggiornamento
- `Connection`: Interfaccia per collezioni paginate di elementi

### Enumerazioni

- `QuizDifficulty`: `EASY`, `MEDIUM`, `HARD`
- `QuizAnswer`: `opt1`, `opt2`, `opt3`, `opt4`
- `QuizOrigin`: `CATALOG`, `CUSTOM`
- `QuizPlacement`: `STANDALONE`, `STORY`, `NEWS`
- `QuizOutcome`: `SUCCESS`, `FAIL`

### Tipi

- `Quiz`: Rappresenta un quiz con le sue proprietà
- `QuizConnection`: Collezione paginata di quiz
- `QuizTranslation`: Traduzioni per un quiz (domande, opzioni, spiegazioni)
- `QuizLog`: Registrazione di un tentativo di quiz da parte di un utente

## Mutation Disponibili

### Invia Quiz

Invia la risposta di un utente a un quiz:

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

Esempio di variabili:

```json
{
  "input": {
    "quizId": "quiz-123",
    "answer": "opt2",
    "context": "default"
  }
}
```

## Funzionalità API

Il contesto App implementa le funzionalità API comuni descritte nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md). Si prega di consultare quel documento per informazioni dettagliate su:

- [Caching](../caratteristiche-comuni.md#caching)
- [Idempotenza](../caratteristiche-comuni.md#idempotenza)
- [Compressione delle Risposte](../caratteristiche-comuni.md#compressione-delle-risposte)
- [Introspezione dello Schema](../caratteristiche-comuni.md#introspezione-dello-schema)

Per il contesto App, l'idempotenza è particolarmente importante durante la creazione o l'aggiornamento dei dati utente. Ad esempio, se si tenta di creare lo stesso utente due volte con richieste concorrenti o all'interno della finestra di idempotenza di 5 minuti, solo la prima chiamata API avrà successo. Le altre chiamate restituiranno lo stesso payload con l'header di idempotenza aggiunto.

## Paginazione

Il contesto App segue l'approccio standard di paginazione descritto nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md#paginazione).

Per le risorse specifiche del contesto App, il pattern di paginazione è implementato come segue:

```graphql
type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}
```

Esempio di query per elencare i quiz con paginazione:

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

Con struttura di input:

```graphql
input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

Per le linee guida e le best practice sulla paginazione, consultare la documentazione delle [Caratteristiche API Comuni](../caratteristiche-comuni.md#linee-guida-per-la-paginazione).

## Limiti di Frequenza

Consultare la documentazione delle [Caratteristiche API Comuni](../caratteristiche-comuni.md#limiti-di-frequenza) per informazioni sui limiti di frequenza.

## Best Practices

1. **Utilizzare variabili GraphQL** per valori dinamici piuttosto che l'interpolazione di stringhe
2. **Richiedere solo i campi necessari** per minimizzare la dimensione della risposta e il tempo di elaborazione
3. **Implementare la gestione degli errori** per gestire con eleganza i diversi scenari di errore
4. **Utilizzare la paginazione** per grandi set di risultati per migliorare le prestazioni
5. **Memorizzare nella cache le risposte** quando appropriato per ridurre le chiamate API

## Esempio di Integrazione

Ecco un esempio di integrazione con l'API del contesto App in un'applicazione JavaScript per inviare una risposta a un quiz:

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
    console.error('Errori GraphQL:', result.errors);
    throw new Error(result.errors[0].message);
  }
  
  return result.data.submitQuiz;
}
```

## Risorse Aggiuntive

- [Documentazione GraphQL](https://graphql.org/learn/)
- [Esploratore Schema Contesto App](#) (richiede autenticazione)
- [Changelog API](#) (richiede autenticazione)
