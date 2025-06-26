# Riferimento API Contesto Portal

Questa sezione documenta gli endpoint API disponibili nel contesto Portal della piattaforma AWorld.

## Introduzione

Il contesto Portal fornisce API per operazioni a livello di piattaforma che i Principal (utenti a livello di piattaforma) possono eseguire per gestire gli Account e eseguire operazioni cross-account. Queste API sono progettate per l'uso in portali amministrativi e strumenti di gestione cross-account.

## Autenticazione

Il contesto Portal utilizza i meccanismi di autenticazione comuni descritti nelle [Caratteristiche API Comuni](../caratteristiche-comuni.md#nozioni-di-base-sullautenticazione). Le API del contesto Portal richiedono specificamente permessi a livello di principal.

### Dettagli Implementazione M2M

A differenza dei contesti App e Dashboard che richiedono l'impersonificazione dell'utente, le API del contesto Portal sono progettate per operare a livello di piattaforma. Quando si utilizzano flussi M2M con le API Portal:

- Assicurati che le credenziali del client abbiano i permessi appropriati a livello di piattaforma
- Non è necessaria l'impersonificazione dell'utente poiché le operazioni vengono eseguite a livello di principal
- Questo approccio è ideale per strumenti di automazione a livello di piattaforma e servizi amministrativi

I flussi M2M del Portal sono particolarmente utili per la gestione degli account, le operazioni cross-account e le attività di amministrazione a livello di piattaforma.

## Endpoint API

### API GraphQL

L'API principale per il contesto Portal è un'API GraphQL:

**Endpoint Attuale:** `https://v1.gql.portal.aworld.cloud/graphql`

> **Nota**: Questi endpoint stanno attualmente esponendo API interne direttamente ai clienti. In futuro, tutte le API saranno accessibili attraverso un singolo reverse proxy, e questi endpoint cambieranno.

### Versionamento API

- **GraphQL**: Le API GraphQL tipicamente utilizzano un approccio di aggiornamenti continui (rolling updates) senza un versionamento formale fino a quando non si verificano cambiamenti incompatibili. Questo permette all'API di evolversi mantenendo la compatibilità all'indietro. Durante questa fase pre-alpha, potrebbero verificarsi cambiamenti più significativi, ma una volta stabile, i cambiamenti seguiranno l'approccio rolling.

- **REST**: Le API REST (quando saranno pubblicate) utilizzeranno un versionamento esplicito (es. v1, v2). I numeri di versione saranno allineati con GraphQL ogni volta che REST richiederà aggiornamenti.

### API REST

Le API REST avranno parità di funzionalità con le API GraphQL ma non sono ancora pubblicate:

**Futuro URL Base:** TBD

## Schema GraphQL

L'API GraphQL del contesto Portal fornisce il seguente tipo di operazioni:

1. **Mutation**: Per creare risorse a livello di piattaforma

Attualmente, non sono implementate operazioni di Query nel contesto Portal.

### Dettagli Schema

```graphql
type Account {
  accountId: ID!
  name: String!
  adminEmail: AWSEmail!
  billingEmail: AWSEmail!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

input CreateAccountInput {
  name: String!
  adminEmail: String!
  billingEmail: String!
}

type Query {} 

type Mutation {
  createAccount(input: CreateAccountInput!): Account!
}

schema {
  query: Query
  mutation: Mutation
}
```

### Contesto Principal

Quando autenticato, le tue richieste API operano nel contesto di:

- Il **Principal** autenticato (utente a livello di piattaforma)
- La configurazione e le impostazioni della **Piattaforma**
- Gli **Account** che hai accesso a gestire

## Mutation Comuni

### Crea Account

Crea un nuovo Account:

```graphql
mutation CreateAccount($input: CreateAccountInput!) {
  createAccount(input: $input) {
    accountId
    name
    adminEmail
    billingEmail
    createdAt
    updatedAt
  }
}
```

Esempio di variabili:

```json
{
  "input": {
    "name": "Organizzazione Esempio",
    "adminEmail": "admin@esempio.com",
    "billingEmail": "fatturazione@esempio.com"
  }
}
```

## Funzionalità API

### Caching

Le Query (operazioni di sola lettura) nel contesto Portal sfruttano un meccanismo di caching interno per migliorare le prestazioni. Questo significa che query identiche ripetute possono essere restituite più velocemente poiché potrebbero essere servite dalla cache.

### Idempotenza

La maggior parte delle operazioni che causano effetti collaterali (come la creazione di risorse) sono idempotenti e i loro risultati vengono memorizzati temporaneamente nella cache per un massimo di 5 minuti. Questo offre diversi vantaggi:

- Se invii la stessa mutation più volte contemporaneamente o in un breve intervallo di tempo, solo la prima richiesta verrà elaborata completamente.
- Le successive richieste identiche entro il periodo di cache restituiranno lo stesso payload della prima chiamata riuscita, con un header aggiuntivo `x-idempotency-key` nella risposta.
- Questo impedisce la creazione di risorse duplicate e aiuta a mantenere la coerenza dei dati durante problemi di rete o tentativi di ripetizione.

Per esempio, se tenti di creare lo stesso account due volte con richieste concorrenti o all'interno della finestra di 5 minuti, solo la prima chiamata API avrà successo. Le altre chiamate restituiranno lo stesso payload con l'header di idempotenza aggiunto.

Dopo la scadenza della cache, ulteriori richieste identiche verranno eseguite nuovamente e la logica di business determinerà la risposta. Ad esempio, i tentativi di creare un account dopo la scadenza della cache probabilmente falliranno perché l'account esiste già.

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

> **Nota**: L'API AWorld è in fase pre-alpha e subisce frequenti aggiornamenti. L'introspezione dello schema è un ottimo modo per scoprire le operazioni più recenti disponibili.

## Paginazione

Le query che ritornano liste in AWorld supportano la paginazione attraverso un pattern "Connection" con la seguente struttura:

```graphql
type AccountConnection {
  items: [Account!]!
  nextToken: String
}
```

Tutte le operazioni che restituiscono liste paginate restituiscono una "Connection" che contiene una lista di elementi del tipo pertinente e un `nextToken` opzionale per richiedere la pagina successiva.

Esempio di query con paginazione:

```graphql
query ListAccounts($input: ListAccountsInput) {
  listAccounts(input: $input) {
    items {
      id
      name
      status
      createdAt
      updatedAt
    }
    nextToken
  }
}
```

L'input per la paginazione segue tipicamente questa struttura:

```graphql
input ListAccountsInput {
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

  const response = await fetch('https://v1.gql.portal.aworld.cloud/graphql', {
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
