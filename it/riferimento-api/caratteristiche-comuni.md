# Caratteristiche API Comuni

Questa pagina documenta le caratteristiche e i comportamenti comuni condivisi tra tutti i contesti API di Cosmos (App, Dashboard e Portal). Consulta la documentazione specifica del contesto per dettagli specifici.

## Nozioni di Base sull'Autenticazione

Tutte le API Cosmos richiedono autenticazione utilizzando un token di accesso valido. Le richieste devono includere un header Authorization:

```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

Per informazioni su come ottenere i token di accesso, consulta la [Guida all'Autenticazione](../guide/autenticazione.md).

### Claim Personalizzati

Le API Cosmos utilizzano claim personalizzati nel token di accesso per applicare permessi e operazioni. Quando si esegue l'accesso, tutti i claim personalizzati necessari sono automaticamente inclusi nel token di accesso.

Ogni contesto richiede claim specifici:
- **Contesto App**: `accountId`, `workspaceId`, `principalId`, `userId`, e altri
- **Contesto Dashboard**: `accountId`, `workspaceId`, `principalId`, `userId`, e altri
- **Contesto Portal**: `principalId` e altri

Consulta la documentazione di ciascun contesto per i requisiti specifici dei claim.

### Flussi Machine-to-Machine (M2M)

Le API possono essere invocate nei flussi machine-to-machine (M2M) utilizzando client credentials. I dettagli di implementazione variano in base al contesto:

- **Contesti App e Dashboard**: Richiede l'header `x-user-id` per impersonare un utente
- **Contesto Portal**: Opera a livello di piattaforma con permessi a livello di principal

Consulta la documentazione specifica del contesto per indicazioni dettagliate sull'implementazione.

## Versionamento API

### GraphQL

Le API GraphQL tipicamente utilizzano un approccio di aggiornamenti continui (rolling updates) senza un versionamento formale fino a quando non si verificano cambiamenti incompatibili. Questo permette all'API di evolversi mantenendo la compatibilità all'indietro. Durante questa fase pre-alpha, potrebbero verificarsi cambiamenti più significativi, ma una volta stabile, i cambiamenti seguiranno l'approccio rolling.

### REST

Le API REST (quando saranno pubblicate) utilizzeranno un versionamento esplicito (es. v1, v2). I numeri di versione saranno allineati con GraphQL ogni volta che REST richiederà aggiornamenti.

## Funzionalità API

### Caching

Le Query (operazioni di sola lettura) sfruttano un meccanismo di caching interno per migliorare le prestazioni. Questo significa che query identiche ripetute possono essere restituite più velocemente poiché potrebbero essere servite dalla cache.

### Idempotenza

La maggior parte delle operazioni che causano effetti collaterali (come la creazione di risorse) sono idempotenti e i loro risultati vengono memorizzati temporaneamente nella cache per un massimo di 5 minuti. Questo offre diversi vantaggi:

- Se invii la stessa mutation più volte contemporaneamente o in un breve intervallo di tempo, solo la prima richiesta verrà elaborata completamente.
- Le successive richieste identiche entro il periodo di cache restituiranno lo stesso payload della prima chiamata riuscita, con un header aggiuntivo `x-idempotency-key` nella risposta.
- Questo impedisce la creazione di risorse duplicate e aiuta a mantenere la coerenza dei dati durante problemi di rete o tentativi di ripetizione.

Dopo la scadenza della cache, ulteriori richieste identiche verranno eseguite nuovamente e la logica di business determinerà la risposta. Ad esempio, i tentativi di creare una risorsa dopo la scadenza della cache probabilmente falliranno perché la risorsa esiste già.

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
type ResourceConnection {
  items: [Resource!]!
  nextToken: String
}
```

Tutte le operazioni che restituiscono liste paginate restituiscono una "Connection" che contiene una lista di elementi del tipo pertinente e un `nextToken` opzionale per richiedere la pagina successiva.

Esempio di query con paginazione:

```graphql
query ListResources($input: ListResourcesInput) {
  listResources(input: $input) {
    items {
      id
      name
      # Altri campi...
    }
    nextToken
  }
}
```

L'input per la paginazione segue tipicamente questa struttura:

```graphql
input ListResourcesInput {
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

## Validazione dei Dati

Le API Cosmos impiegano una rigorosa validazione per tutti gli input di dati per garantire coerenza, sicurezza e integrità dei dati. Comprendere queste regole di validazione ti aiuta a costruire integrazioni più robuste.

### Tipi Comuni e Regole di Validazione

Il sistema applica regole di validazione specifiche per diversi tipi di dati:

#### Identificatori

- **Account ID, Workspace ID**: Devono essere esattamente della lunghezza specificata, contenendo solo caratteri alfanumerici, underscore e trattini
- **User ID, Principal ID**: Devono essere in formato nanoid valido
- **Client ID**: Identificatori di stringa non vuoti

#### Dati di tipo Stringa

- **Nomi**: 
  - Devono essere da 2 a 50 caratteri
  - Possono contenere lettere da più script (Latino, Cinese, Arabo, ecc.)
  - Possono includere trattini, apostrofi e spazi
  - Non possono contenere spazi consecutivi

#### Timestamp

- **Created/Updated At**: Devono essere stringhe datetime ISO valide

#### Codici Lingua

- I codici lingua seguono i tag linguistici IETF
- Tipicamente codici semplici come "it" o "fr"
- Alcune eccezioni come il Cinese che usa "zh-TW" e "zh-CN"

#### Fusi Orari

- Tutti i valori di fuso orario devono essere identificatori di fuso orario IANA validi (es., "Europe/Rome", "America/New_York")

### Comportamento della Validazione

Quando la validazione fallisce, l'API restituisce appropriate risposte di errore con dettagli sul fallimento della validazione. Queste risposte includono:

- Il campo che ha fallito la validazione
- Una descrizione del motivo per cui la validazione è fallita
- Eventuali vincoli o formati previsti

Queste informazioni ti aiutano a identificare e risolvere rapidamente i problemi di dati nelle tue richieste.

## Selezione della Lingua

Per le API rivolte all'utente (come il contesto App), le entità restituiranno dati e metadati in una singola lingua. Il meccanismo di selezione della lingua funziona come segue:

1. La lingua è determinata dal claim personalizzato `lang` nel token di accesso
2. Questo claim viene impostato automaticamente quando un utente effettua l'accesso, in base alle preferenze del suo profilo
3. Tutti i contenuti verranno restituiti nella lingua specificata da questo claim
4. Se il contenuto non è disponibile nella lingua richiesta, potrebbe ricadere su una lingua predefinita (tipicamente l'inglese)

> **Importante**: Se un utente modifica la preferenza della lingua nel proprio profilo, il token di accesso deve essere aggiornato per ricevere i contenuti nella nuova lingua selezionata. La semplice modifica dell'impostazione del profilo senza ottenere un nuovo token non influirà sulle risposte dell'API.

Questo comportamento si applica a tutti i contenuti traducibili nel sistema, incluse domande e risposte dei quiz, testo dell'interfaccia utente e qualsiasi altra risorsa localizzata.

## Best Practices

1. **Utilizzare variabili GraphQL** per valori dinamici piuttosto che l'interpolazione di stringhe
2. **Richiedere solo i campi necessari** per minimizzare la dimensione della risposta e il tempo di elaborazione
3. **Implementare la gestione degli errori** per gestire con eleganza i diversi scenari di errore
4. **Utilizzare la paginazione** per grandi set di risultati per migliorare le prestazioni
5. **Proteggere gli endpoint** implementando controlli di autorizzazione appropriati
6. **Gestire l'aggiornamento del token** quando le preferenze dell'utente cambiano (ad esempio, per garantire che i contenuti siano forniti nella lingua preferita, che il fuso orario selezionato sia rispettato, ecc.)
