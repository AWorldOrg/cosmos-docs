# Riferimento API Contesto App

Questa sezione documenta gli endpoint API disponibili nel contesto App della piattaforma Cosmos.

## Introduzione

Il contesto App fornisce API per l'integrazione e l'estensione delle applicazioni costruite sulla piattaforma Cosmos. Queste API sono progettate per l'uso in applicazioni per utenti finali e interfacce lato client.

## Autenticazione

Tutte le API del contesto App richiedono autenticazione. Le richieste devono includere un token di accesso valido nell'header Authorization:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Per informazioni su come ottenere i token di accesso, consultare la [Guida all'Autenticazione](../../guide/autenticazione.md).

### Claim Personalizzati

Le API del contesto App utilizzano claim personalizzati nel token di accesso per applicare permessi e operazioni. Alcuni dei claim personalizzati comuni includono (ma non sono limitati a):
- `accountId`
- `workspaceId`
- `principalId`
- `userId`

Questa lista non è esaustiva e potrebbero essere richiesti claim aggiuntivi a seconda dell'operazione specifica. Quando si esegue l'accesso come utente normale, tutti i claim personalizzati necessari sono automaticamente inclusi nel token di accesso.

### Flussi Machine-to-Machine (M2M)

Le API che richiedono accesso a "livello utente" possono essere invocate anche nei flussi machine-to-machine (M2M) utilizzando client credentials. Quando si utilizzano flussi M2M, il chiamante deve includere l'userId dell'utente da impersonare in un header con ogni chiamata:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

Questo consente la corretta esecuzione delle API di "livello utente" anche nelle implementazioni M2M, dove il tuo servizio potrebbe dover eseguire azioni per conto degli utenti. Questo approccio è particolarmente utile per i servizi backend che devono interagire con l'API in modo programmatico, mantenendo il contesto dell'utente.

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

### Caching

Le Query (operazioni di sola lettura) nel contesto App sfruttano un meccanismo di caching interno per migliorare le prestazioni. Questo significa che query identiche ripetute possono essere restituite più velocemente poiché potrebbero essere servite dalla cache.

### Idempotenza

La maggior parte delle operazioni che causano effetti collaterali (come la creazione di risorse) sono idempotenti e i loro risultati vengono memorizzati temporaneamente nella cache per un massimo di 5 minuti. Questo offre diversi vantaggi:

- Se invii la stessa mutation più volte contemporaneamente o in un breve intervallo di tempo, solo la prima richiesta verrà elaborata completamente.
- Le successive richieste identiche entro il periodo di cache restituiranno lo stesso payload della prima chiamata riuscita, con un header aggiuntivo `x-idempotency-key` nella risposta.
- Questo impedisce la creazione di risorse duplicate e aiuta a mantenere la coerenza dei dati durante problemi di rete o tentativi di ripetizione.

Per esempio, se tenti di creare lo stesso utente due volte con richieste concorrenti o all'interno della finestra di 5 minuti, solo la prima chiamata API avrà successo. Le altre chiamate restituiranno lo stesso payload con l'header di idempotenza aggiunto.

Dopo la scadenza della cache, ulteriori richieste identiche verranno eseguite nuovamente e la logica di business determinerà la risposta. Ad esempio, i tentativi di creare un utente dopo la scadenza della cache probabilmente falliranno perché l'utente esiste già.

### Compressione delle Risposte

Per ridurre le dimensioni del payload e migliorare i tempi di trasferimento, è possibile abilitare la compressione includendo il seguente header nelle richieste:

```
Accept-Encoding: gzip
```

### Introspezione dello Schema

GraphQL fornisce capacità di introspezione che consentono di esplorare le operazioni, i tipi e i campi disponibili. È possibile utilizzare le query di introspezione standard di GraphQL per scoprire i dettagli dello schema:

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

Molti client GraphQL (per esempio Postman) forniscono automaticamente funzionalità di introspezione, permettendo di navigare lo schema e le operazioni disponibili.

> **Nota**: L'API Cosmos è in fase pre-alpha e subisce frequenti aggiornamenti. L'introspezione dello schema è un ottimo modo per scoprire le operazioni più recenti disponibili.

## Paginazione

Le query che ritornano liste in Cosmos supportano la paginazione attraverso un pattern "Connection" con la seguente struttura:

```graphql
type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}
```

Tutte le operazioni che restituiscono liste paginate restituiscono una "Connection" che contiene una lista di elementi del tipo pertinente e un `nextToken` opzionale per richiedere la pagina successiva.

Esempio di query con paginazione:

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

L'input per la paginazione segue tipicamente questa struttura:

```graphql
input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

Esempio di variabili:

```json
{
  "input": {
    "limit": 10,
    "nextToken": "eyJsYXN0SXRlbUlkIjoiMTIzNDUiLCJsYXN0SXRlbVZhbHVlIjoidGVzdCJ9"
  }
}
```

### Linee Guida per la Paginazione

- È possibile specificare un `limit` opzionale per controllare il numero di elementi restituiti per pagina
- Se non viene fornito alcun limite, il sistema utilizzerà un valore predefinito
- Per recuperare la pagina successiva, passare il `nextToken` dalla risposta precedente
- **Importante**: Un `nextToken` è valido solo se utilizzato con lo stesso `limit` che è stato utilizzato nella richiesta originale. Non dovresti mischiare token restituiti da chiamate con valori di limite diversi

## Limiti di Frequenza

Nella fase pre-alpha, non sono ancora applicati limiti di frequenza.

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
