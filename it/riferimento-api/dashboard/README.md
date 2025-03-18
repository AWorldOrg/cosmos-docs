# Riferimento API Contesto Dashboard

Questa sezione documenta gli endpoint API disponibili nel contesto Dashboard della piattaforma Cosmos.

## Introduzione

Il contesto Dashboard fornisce API per funzioni di amministrazione e gestione, consentendo ai proprietari degli account e agli amministratori di configurare e monitorare i loro ambienti Cosmos. Queste API sono progettate per l'uso in interfacce amministrative e strumenti di gestione.

## Autenticazione

Tutte le API del contesto Dashboard richiedono autenticazione con permessi a livello di principal o amministratore. Le richieste devono includere un token di accesso valido nell'header Authorization:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Per informazioni su come ottenere i token di accesso, consultare la [Guida all'Autenticazione](../../guide/autenticazione.md).

## Endpoint API

### API GraphQL

L'API principale per il contesto Dashboard è un'API GraphQL:

**Endpoint:** `https://api.aworld.cloud/dashboard/graphql`

### API REST

Mentre GraphQL è il tipo di API principale, alcune operazioni specifiche sono disponibili come endpoint REST:

**URL Base:** `https://api.aworld.cloud/dashboard`

## Schema GraphQL

L'API GraphQL del contesto Dashboard fornisce i seguenti tipi principali di operazioni:

1. **Query**: Per recuperare dati su account, workspace, utenti e configurazione di sistema
2. **Mutation**: Per creare, aggiornare o eliminare risorse e configurazioni

### Contesto Amministrativo

Quando autenticato, le tue richieste API operano nel contesto di:

- Il **Principal** autenticato (utente a livello di piattaforma)
- L'**Account** che hai accesso a gestire
- I **Workspace** all'interno di quell'account

## Query Comuni

### Informazioni Account

Recupera informazioni su un account:

```graphql
query GetAccount($id: ID!) {
  account(id: $id) {
    id
    name
    status
    createdAt
    updatedAt
    workspaces {
      id
      name
      environment
    }
  }
}
```

### Utenti Account

Recupera gli utenti associati a un account:

```graphql
query GetAccountUsers($accountId: ID!) {
  account(id: $accountId) {
    id
    name
    users {
      id
      email
      firstName
      lastName
      roles {
        id
        name
      }
      workspace {
        id
        name
      }
    }
  }
}
```

### Informazioni Workspace

Recupera informazioni dettagliate su un workspace:

```graphql
query GetWorkspace($id: ID!) {
  workspace(id: $id) {
    id
    name
    description
    environment
    status
    createdAt
    updatedAt
    account {
      id
      name
    }
    users {
      id
      email
      firstName
      lastName
    }
  }
}
```

## Mutation Comuni

### Crea Workspace

Crea un nuovo workspace all'interno di un account:

```graphql
mutation CreateWorkspace($input: CreateWorkspaceInput!) {
  createWorkspace(input: $input) {
    id
    name
    description
    environment
    status
    createdAt
  }
}
```

Esempio di variabili:

```json
{
  "input": {
    "accountId": "account-123",
    "name": "Ambiente di Produzione",
    "description": "Workspace di produzione per applicazioni live",
    "environment": "PRODUCTION"
  }
}
```

### Invita Utente

Invita un utente a unirsi a un workspace:

```graphql
mutation InviteUser($input: InviteUserInput!) {
  inviteUser(input: $input) {
    id
    email
    status
    expiresAt
  }
}
```

Esempio di variabili:

```json
{
  "input": {
    "email": "utente@esempio.com",
    "workspaceId": "workspace-123",
    "roleIds": ["role-456"]
  }
}
```

### Aggiorna Impostazioni Account

Aggiorna le impostazioni per un account:

```graphql
mutation UpdateAccountSettings($id: ID!, $input: UpdateAccountSettingsInput!) {
  updateAccountSettings(id: $id, input: $input) {
    id
    name
    settings {
      allowUserRegistration
      requireMfa
      sessionTimeout
    }
  }
}
```

Esempio di variabili:

```json
{
  "id": "account-123",
  "input": {
    "settings": {
      "allowUserRegistration": true,
      "requireMfa": true,
      "sessionTimeout": 3600
    }
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
      "path": ["account"],
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
query GetPaginatedWorkspaces($accountId: ID!, $first: Int, $after: String) {
  account(id: $accountId) {
    workspaces(first: $first, after: $after) {
      edges {
        node {
          id
          name
          environment
        }
        cursor
      }
      pageInfo {
        hasNextPage
        endCursor
      }
    }
  }
}
```

Esempio di variabili:

```json
{
  "accountId": "account-123",
  "first": 10,
  "after": "cursor_from_previous_page"
}
```

## Limiti di Frequenza

Nella fase pre-alpha, non sono ancora applicati limiti di frequenza.

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

  const response = await fetch('https://api.aworld.cloud/dashboard/graphql', {
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
