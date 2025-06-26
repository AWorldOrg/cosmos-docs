# Riferimento API Contesto Dashboard

Questa sezione documenta gli endpoint API disponibili nel contesto Dashboard della piattaforma AWorld.

## Introduzione

Il contesto Dashboard fornisce API per funzioni di amministrazione e gestione, consentendo ai proprietari degli account e agli amministratori di configurare e monitorare i loro ambienti AWorld. Queste API sono progettate per l'uso in interfacce amministrative e strumenti di gestione.

## Autenticazione

Il contesto Dashboard utilizza i meccanismi di autenticazione comuni descritti nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md#nozioni-di-base-sullautenticazione). Le API del contesto Dashboard richiedono specificamente permessi a livello di principal o amministratore.

### Dettagli Implementazione M2M

Per le API del contesto Dashboard che richiedono accesso a "livello utente" nei flussi machine-to-machine (M2M), è necessario includere l'userId dell'utente da impersonare in un header con ogni chiamata:

```
x-user-id: USER_ID_TO_IMPERSONATE
```

Questo consente al tuo servizio di eseguire azioni per conto di specifici utenti utilizzando client credentials per l'autenticazione.

## Endpoint API

### API GraphQL

L'API principale per il contesto Dashboard è un'API GraphQL:

**Endpoint Attuale:** `https://v1.gql.dashboard.aworld.cloud/graphql`

> **Nota**: Questi endpoint stanno attualmente esponendo API interne direttamente ai clienti. In futuro, tutte le API saranno accessibili attraverso un singolo reverse proxy, e questi endpoint cambieranno.

### Versionamento API

- **GraphQL**: Le API GraphQL tipicamente utilizzano un approccio di aggiornamenti continui (rolling updates) senza un versionamento formale fino a quando non si verificano cambiamenti incompatibili. Questo permette all'API di evolversi mantenendo la compatibilità all'indietro. Durante questa fase pre-alpha, potrebbero verificarsi cambiamenti più significativi, ma una volta stabile, i cambiamenti seguiranno l'approccio rolling.

- **REST**: Le API REST (quando saranno pubblicate) utilizzeranno un versionamento esplicito (es. v1, v2). I numeri di versione saranno allineati con GraphQL ogni volta che REST richiederà aggiornamenti.

### API REST

Le API REST avranno parità di funzionalità con le API GraphQL ma non sono ancora pubblicate:

**Futuro URL Base:** TBD

## Schema GraphQL

L'API GraphQL del contesto Dashboard fornisce i seguenti tipi principali di operazioni:

1. **Query**: Per recuperare dati su utenti, quiz e risorse del workspace
2. **Mutation**: Per creare e aggiornare risorse

### Contesto Amministrativo

Quando autenticato, le tue richieste API operano nel contesto di:

- Il **Principal** autenticato (utente a livello di piattaforma)
- L'**Account** che hai accesso a gestire
- Lo specifico **Workspace** con cui stai attualmente lavorando

## Dettagli Schema

### Tipi Scalari

- `AWSDateTime`, `AWSDate`, `AWSTime`, `AWSTimestamp`
- `AWSEmail`, `AWSJSON`, `AWSURL`, `AWSPhone`, `AWSIPAddress`
- `Long`

### Interfacce

```graphql
interface Node {
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

interface Connection {
  items: [Node]
  nextToken: String
}
```

### Tipi Utente

```graphql
type User {
  userId: ID!
  principalId: String!
  workspaceId: String!
  accountId: String!
  externalId: String
  lang: String!
  timezone: String!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type UserConnection {
  items: [User!]!
  nextToken: String
}

input CreateUserInput {
  email: AWSEmail!
  firstName: String
  lastName: String
  lang: String
  timezone: String
  externalId: String
}
```

### Tipi Quiz

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

input ListQuizzesInput {
  limit: Int
  nextToken: String
}
```

## Query Comuni

### Lista Utenti

Recupera gli utenti nel workspace corrente:

```graphql
query ListUsers($nextToken: String) {
  users(nextToken: $nextToken) {
    items {
      userId
      principalId
      workspaceId
      accountId
      externalId
      lang
      timezone
      createdAt
      updatedAt
    }
    nextToken
  }
}
```

### Lista Quiz

Recupera i quiz con paginazione:

```graphql
query ListQuizzes($input: ListQuizzesInput) {
  quizzes(input: $input) {
    items {
      quizId
      difficulty
      answer
      origin
      placement
      quizCatalogId
      syncWithCatalog
      createdAt
      updatedAt
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
    nextToken
  }
}
```

## Mutation Comuni

### Crea Utente

Crea un nuovo utente nel workspace corrente:

```graphql
mutation CreateUser($input: CreateUserInput!) {
  createUser(input: $input) {
    userId
    principalId
    workspaceId
    accountId
    externalId
    lang
    timezone
    createdAt
    updatedAt
  }
}
```

Esempio di variabili:

```json
{
  "input": {
    "email": "utente@esempio.com",
    "firstName": "Mario",
    "lastName": "Rossi",
    "lang": "it",
    "timezone": "Europe/Rome",
    "externalId": "ext-12345"
  }
}
```

> **Importante**: Si raccomanda vivamente di impostare sempre un `externalId` quando si creano utenti. Questo identificatore collega l'utente in AWorld al tuo sistema esterno. Senza un `externalId`, potrebbe diventare impossibile tracciare quale utente in AWorld corrisponde a quale utente nella tua piattaforma, specialmente in scenari che coinvolgono operazioni di gestione utenti. L'`externalId` dovrebbe essere un identificatore stabile e univoco proveniente dal tuo sistema.

## Funzionalità API

Il contesto Dashboard implementa le funzionalità API comuni descritte nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md). Si prega di consultare quel documento per informazioni dettagliate su:

- [Caching](../caratteristiche-comuni.md#caching)
- [Idempotenza](../caratteristiche-comuni.md#idempotenza)
- [Compressione delle Risposte](../caratteristiche-comuni.md#compressione-delle-risposte)
- [Introspezione dello Schema](../caratteristiche-comuni.md#introspezione-dello-schema)

Per il contesto Dashboard, l'idempotenza è particolarmente critica per le operazioni amministrative come la creazione di utenti e la gestione dei workspace. Ad esempio, se si tenta di creare lo stesso utente o workspace due volte all'interno della finestra di idempotenza di 5 minuti, solo la prima chiamata API avrà successo. Questo impedisce la creazione di risorse duplicate durante le operazioni amministrative, che potrebbero altrimenti causare problemi significativi.

## Paginazione

Il contesto Dashboard segue l'approccio standard di paginazione descritto nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md#paginazione).

Per le linee guida e le best practice sulla paginazione, consultare la documentazione delle [Caratteristiche API Comuni](../caratteristiche-comuni.md#linee-guida-per-la-paginazione).

## Limiti di Frequenza

Consultare la documentazione delle [Caratteristiche API Comuni](../caratteristiche-comuni.md#limiti-di-frequenza) per informazioni sui limiti di frequenza.

## Operazioni Amministrative

Il contesto Dashboard fornisce diverse operazioni amministrative per gestire la piattaforma:

### Gestione Utenti

- Creazione, aggiornamento e disattivazione degli utenti
- Assegnazione di ruoli e permessi
- Gestione dell'accesso degli utenti ai workspace

### Gestione Workspace

- Creazione e configurazione dei workspace
- Impostazione di configurazioni specifiche per workspace
- Monitoraggio dello stato e dell'utilizzo del workspace

### Configurazione Account

- Gestione delle impostazioni dell'account
- Configurazione delle politiche di sicurezza
- Configurazione di integrazioni con altri sistemi

## Best Practices

1. **Utilizzare variabili GraphQL** per valori dinamici piuttosto che l'interpolazione di stringhe
2. **Richiedere solo i campi necessari** per minimizzare la dimensione della risposta e il tempo di elaborazione
3. **Implementare la gestione degli errori** per gestire con eleganza i diversi scenari di errore
4. **Utilizzare la paginazione** per grandi set di risultati per migliorare le prestazioni
5. **Proteggere gli endpoint amministrativi** implementando controlli di autorizzazione appropriati

## Esempio di Integrazione

Ecco un esempio di integrazione con l'API del contesto Dashboard in un'applicazione JavaScript:

```javascript
async function fetchAccountWorkspaces(accountId) {
  const query = `
    query GetAccountWorkspaces($accountId: ID!) {
      account(id: $accountId) {
        id
        name
        workspaces {
          id
          name
          environment
          status
        }
      }
    }
  `;

  const response = await fetch('https://v1.gql.dashboard.aworld.cloud/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
    },
    body: JSON.stringify({
      query,
      variables: { accountId }
    })
  });

  const result = await response.json();
  
  if (result.errors) {
    console.error('Errori GraphQL:', result.errors);
    throw new Error(result.errors[0].message);
  }
  
  return result.data;
}
```

## Risorse Aggiuntive

- [Documentazione GraphQL](https://graphql.org/learn/)
- [Esploratore Schema Contesto Dashboard](#) (richiede autenticazione)
- [Changelog API](#) (richiede autenticazione)
