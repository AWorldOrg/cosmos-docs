# Riferimento API Contesto Portal

Questa sezione documenta gli endpoint API disponibili nel contesto Portal della piattaforma Cosmos.

## Introduzione

Il contesto Portal fornisce API per operazioni a livello di piattaforma che i Principal (utenti a livello di piattaforma) possono eseguire per gestire gli Account e eseguire operazioni cross-account. Queste API sono progettate per l'uso in portali amministrativi e strumenti di gestione cross-account.

## Autenticazione

Tutte le API del contesto Portal richiedono autenticazione con permessi a livello di Principal. Le richieste devono includere un token di accesso valido nell'header Authorization:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Per informazioni su come ottenere i token di accesso, consultare la [Guida all'Autenticazione](../../guide/autenticazione.md).

## Endpoint API

### API GraphQL

L'API principale per il contesto Portal è un'API GraphQL:

**Endpoint:** `https://api.aworld.cloud/portal/graphql`

### API REST

Mentre GraphQL è il tipo di API principale, alcune operazioni specifiche sono disponibili come endpoint REST:

**URL Base:** `https://api.aworld.cloud/portal`

## Schema GraphQL

L'API GraphQL del contesto Portal fornisce i seguenti tipi principali di operazioni:

1. **Query**: Per recuperare dati su più Account
2. **Mutation**: Per creare, aggiornare o eliminare risorse a livello di piattaforma

### Contesto Principal

Quando autenticato, le tue richieste API operano nel contesto di:

- Il **Principal** autenticato (utente a livello di piattaforma)
- La configurazione e le impostazioni della **Piattaforma**
- Gli **Account** che hai accesso a gestire

## Query Comuni

### Lista Account

Recupera una lista di Account disponibili per il Principal autenticato:

```graphql
query ListAccounts {
  accounts {
    id
    name
    status
    createdAt
    updatedAt
    workspaceCount
  }
}
```

### Profilo Principal

Recupera informazioni sul Principal attualmente autenticato:

```graphql
query GetPrincipalProfile {
  me {
    id
    email
    firstName
    lastName
    roles {
      id
      name
    }
    permissions
  }
}
```

### Dettagli Account

Recupera informazioni dettagliate su uno specifico Account:

```graphql
query GetAccountDetails($id: ID!) {
  account(id: $id) {
    id
    name
    status
    createdAt
    updatedAt
    settings {
      allowUserRegistration
      requireMfa
      sessionTimeout
    }
    workspaces {
      id
      name
      environment
      status
    }
    users {
      totalCount
      activeCount
    }
  }
}
```

## Mutation Comuni

### Crea Account

Crea un nuovo Account:

```graphql
mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    id
    name
    status
    createdAt
  }
}
```

Esempio di variabili:

```json
{
  "input": {
    "name": "Organizzazione Esempio",
    "adminEmail": "admin@esempio.com",
    "settings": {
      "allowUserRegistration": true,
      "requireMfa": false,
      "sessionTimeout": 3600
    }
  }
}
```

### Aggiorna Ruolo Principal

Aggiorna il ruolo di un Principal:

```graphql
mutation UpdatePrincipalRole($id: ID!, $input: UpdatePrincipalRoleInput!) {
  updatePrincipalRole(id: $id, input: $input) {
    id
    email
    roles {
      id
      name
    }
  }
}
```

Esempio di variabili:

```json
{
  "id": "principal-123",
  "input": {
    "roleIds": ["role-admin"]
  }
}
```

### Sospendi Account

Sospendi un Account:

```graphql
mutation SuspendAccount($id: ID!) {
  suspendAccount(id: $id) {
    id
    name
    status
  }
}
```

## Gestione degli Errori

Le risposte GraphQL possono includere errori all'interno dell'array `errors`:

```json
{
  "errors": [
    {
      "message": "Non autorizzato ad accedere a questa risorsa",
      "locations": [{ "line": 2, "column": 3 }],
      "path": ["accounts"],
      "extensions": {
        "code": "FORBIDDEN"
      }
    }
  ],
  "data": null
}
```

Codici di errore comuni:

- `UNAUTHENTICATED`: Autenticazione mancante o non valida
- `FORBIDDEN`: Autenticazione valida ma permessi insufficienti
- `BAD_USER_INPUT`: Parametri di input non validi
- `NOT_FOUND`: Risorsa richiesta non trovata

## Paginazione

Le query di lista tipicamente supportano parametri di paginazione:

```graphql
query GetPaginatedAccounts($first: Int, $after: String) {
  accounts(first: $first, after: $after) {
    edges {
      node {
        id
        name
        status
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

Esempio di variabili:

```json
{
  "first": 10,
  "after": "cursor_from_previous_page"
}
```

## Limiti di Frequenza

Nella fase pre-alpha, non sono ancora applicati limiti di frequenza.

## Operazioni di Piattaforma

Il contesto Portal fornisce diverse operazioni a livello di piattaforma:

### Gestione Account

- Creazione, aggiornamento e sospensione degli Account
- Gestione delle impostazioni e configurazioni degli Account
- Visualizzazione delle metriche di utilizzo e dello stato degli Account

### Gestione Principal

- Creazione e gestione degli utenti a livello di piattaforma (Principal)
- Assegnazione di ruoli e permessi ai Principal
- Gestione dell'accesso dei Principal agli Account

### Configurazione Piattaforma

- Configurazione delle impostazioni a livello di piattaforma
- Gestione dei ruoli e permessi disponibili
- Configurazione delle integrazioni a livello di piattaforma

## Best Practices

1. **Utilizzare variabili GraphQL** per valori dinamici piuttosto che l'interpolazione di stringhe
2. **Richiedere solo i campi necessari** per minimizzare la dimensione della risposta e il tempo di elaborazione
3. **Implementare la gestione degli errori** per gestire con eleganza i diversi scenari di errore
4. **Utilizzare la paginazione** per grandi set di risultati per migliorare le prestazioni
5. **Proteggere gli endpoint a livello di piattaforma** con controlli di autorizzazione appropriati

## Esempio di Integrazione

Ecco un esempio di integrazione con l'API del contesto Portal in un'applicazione JavaScript:

```javascript
async function fetchAvailableAccounts() {
  const query = `
    query GetAccounts {
      accounts {
        id
        name
        status
        createdAt
        workspaceCount
      }
    }
  `;

  const response = await fetch('https://api.aworld.cloud/portal/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
    },
    body: JSON.stringify({ query })
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
- [Esploratore Schema Contesto Portal](#) (richiede autenticazione)
- [Changelog API](#) (richiede autenticazione)
