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

Le API REST avranno parità di funzionalità con le API GraphQL ma non sono ancora pubblicate:

**Futuro URL Base:** `https://api.aworld.cloud/dashboard`

## Schema GraphQL

L'API GraphQL del contesto Dashboard fornisce i seguenti tipi principali di operazioni:

1. **Query**: Per recuperare dati su account, workspace, utenti e configurazione di sistema
2. **Mutation**: Per creare, aggiornare o eliminare risorse e configurazioni

### Contesto Amministrativo

Quando autenticato, le tue richieste API operano nel contesto di:

- Il **Principal** autenticato (utente a livello di piattaforma)
- L'**Account** che hai accesso a gestire
- Lo specifico **Workspace** con cui stai attualmente lavorando

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

## Funzionalità API

### Caching

Le Query (operazioni di sola lettura) nel contesto Dashboard sfruttano un meccanismo di caching interno per migliorare le prestazioni. Questo significa che query identiche ripetute possono essere restituite più velocemente poiché potrebbero essere servite dalla cache.

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
type WorkspaceConnection {
  items: [Workspace!]!
  nextToken: String
}
```

Tutte le operazioni che restituiscono liste paginate restituiscono una "Connection" che contiene una lista di elementi del tipo pertinente e un `nextToken` opzionale per richiedere la pagina successiva.

Esempio di query con paginazione:

```graphql
query ListWorkspaces($input: ListWorkspacesInput) {
  listWorkspaces(input: $input) {
    items {
      id
      name
      description
      environment
      status
      createdAt
    }
    nextToken
  }
}
```

L'input per la paginazione segue tipicamente questa struttura:

```graphql
input ListWorkspacesInput {
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
