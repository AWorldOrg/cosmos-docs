Questa pagina documenta le funzionalita e i comportamenti comuni condivisi tra tutti i contesti delle API di AWorld (Consumer/App, Admin/Dashboard e Portal). Consulta la documentazione specifica di ciascun contesto per i dettagli relativi.

## Fondamenti dell'Autenticazione

Tutte le API di AWorld richiedono l'autenticazione tramite un token di accesso valido. Le richieste devono includere un header Authorization:

```
Authorization: Bearer IL_TUO_TOKEN_DI_ACCESSO
```

Per informazioni su come ottenere i token di accesso, consulta la sezione [Autenticazione](apidog://link/pages/1215379).

### Custom Claims

Le API di AWorld utilizzano custom claims nel token di accesso per applicare permessi e operazioni. Quando si effettua un accesso (sign-in), tutti i custom claims necessari vengono automaticamente inclusi nel token di accesso.

Ogni contesto richiede claim specifici:
- **Contesto App**: `accountId`, `workspaceId`, `principalId`, `userId` e altri
- **Contesto Dashboard**: `accountId`, `workspaceId`, `principalId`, `userId` e altri
- **Contesto Portal**: `principalId` e altri

Consulta la documentazione di ciascun contesto per i requisiti specifici dei claim.

### Flussi Machine-to-Machine (M2M)

Le API possono essere invocate in flussi machine-to-machine (M2M) utilizzando le credenziali client. I dettagli di implementazione variano in base al contesto:

- **Contesti App e Dashboard**: Richiedono l'header `x-user-id` per impersonare un utente
- **Contesto Portal**: Opera a livello di piattaforma con permessi a livello di principal

Consulta la documentazione specifica del contesto per una guida dettagliata sull'implementazione.

## Versionamento delle API

### GraphQL

Le API GraphQL utilizzano tipicamente un approccio ad aggiornamenti continui senza versionamento formale fino a quando non si verificano modifiche incompatibili (*breaking changes*). Questo consente all'API di evolversi mantenendo la compatibilita con le versioni precedenti. Durante questa fase pre-alpha, possono verificarsi cambiamenti piu significativi, ma una volta stabile, le modifiche seguiranno l'approccio ad aggiornamenti continui.

### REST

Le API REST (quando pubblicate) utilizzeranno un versionamento esplicito (ad esempio, v1, v2). I numeri di versione saranno allineati con GraphQL ogni volta che REST richiede aggiornamenti.

## Funzionalita delle API

### Caching

Le query (operazioni di sola lettura) sfruttano un meccanismo di caching interno per migliorare le prestazioni. Questo significa che query identiche ripetute possono restituire risultati piu velocemente poiche potrebbero essere servite dalla cache.

### Idempotency

La maggior parte delle operazioni che causano effetti collaterali (come la creazione di risorse) sono idempotenti e i loro risultati vengono memorizzati temporaneamente in cache per un massimo di 5 minuti. Questo offre diversi vantaggi:

- Se invii la stessa mutation piu volte contemporaneamente o entro un breve intervallo di tempo, solo la prima richiesta verra elaborata completamente.
- Le successive richieste identiche entro il periodo di cache restituiranno lo stesso payload della prima chiamata riuscita, con un header `x-idempotency-key` aggiuntivo nella risposta.
- Questo previene la creazione di risorse duplicate e aiuta a mantenere la consistenza dei dati durante problemi di rete o tentativi ripetuti.

Dopo la scadenza della cache, ulteriori richieste identiche verranno eseguite nuovamente e la logica di business determinera la risposta. Ad esempio, i tentativi di creare una risorsa dopo la scadenza della cache probabilmente falliranno perche la risorsa esiste gia.

### Compressione delle Risposte

Per ridurre la dimensione del payload e migliorare i tempi di trasferimento, puoi abilitare la compressione includendo il seguente header nelle tue richieste:

```
Accept-Encoding: gzip
```

### Introspezione dello Schema

GraphQL fornisce funzionalita di introspezione che ti permettono di esplorare le operazioni, i tipi e i campi disponibili. Puoi utilizzare le query di introspezione standard di GraphQL per scoprire i dettagli dello schema:

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

Molti client GraphQL (ad esempio Postman) forniscono automaticamente funzionalita di introspezione, permettendoti di navigare lo schema e le operazioni disponibili.

> **Nota**: Le API di AWorld sono in fase pre-alpha e vengono aggiornate frequentemente. L'introspezione dello schema e un ottimo modo per scoprire le ultime operazioni disponibili.

## Pagination

Le query di tipo lista in AWorld supportano la pagination attraverso un pattern Connection con la seguente struttura:

```graphql
type ResourceConnection {
  items: [Resource!]!
  nextToken: String
}
```

Tutte le operazioni che restituiscono liste paginate ritornano una "Connection" che contiene una lista di elementi del tipo pertinente e un nextToken opzionale per richiedere la pagina successiva.

Esempio di query con pagination:

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

L'input per la pagination segue tipicamente questa struttura:

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

### Linee Guida per la Pagination

- Puoi specificare un `limit` opzionale per controllare il numero di elementi restituiti per pagina
- Se non viene fornito un limite, il sistema utilizzera un valore predefinito
- Per recuperare la pagina successiva, passa il nextToken dalla risposta precedente
- **Importante**: Un nextToken e valido solo se utilizzato con lo stesso `limit` usato nella richiesta originale. Non dovresti mischiare token restituiti da chiamate con valori di limite diversi

## Rate Limiting

Nella fase pre-alpha, non sono ancora applicati limiti di frequenza (rate limiting).

## Validazione dei Dati

Le API di AWorld applicano una validazione rigorosa su tutti i dati in input per garantire consistenza, sicurezza e integrita dei dati. Comprendere queste regole di validazione ti aiuta a costruire integrazioni piu robuste.

### Tipi Comuni e Regole di Validazione

Il sistema applica regole di validazione specifiche per diversi tipi di dati:

#### Identificatori

- **Account ID, Workspace ID**: Devono avere esattamente la lunghezza specificata, contenendo solo caratteri alfanumerici, trattini bassi e trattini
- **User ID, Principal ID**: Devono essere in formato nanoid valido
- **Client ID**: Identificatori stringa non vuoti

#### Dati Stringa

- **Nomi**:
  - Devono essere di 2-50 caratteri
  - Possono contenere lettere da diversi sistemi di scrittura (Latino, Cinese, Arabo, ecc.)
  - Possono includere trattini, apostrofi e spazi
  - Non possono contenere spazi consecutivi

#### Timestamp

- **Created/Updated At**: Devono essere stringhe datetime ISO valide

#### Codici Lingua

- I codici lingua seguono i tag linguistici IETF
- Tipicamente codici semplici come "en" o "fr"
- Alcune eccezioni come il cinese che utilizza "zh-TW" e "zh-CN"

#### Fusi Orari

- Tutti i valori dei fusi orari devono essere identificatori di fuso orario IANA validi (ad esempio, "Europe/Rome", "America/New_York")

### Comportamento della Validazione

Quando la validazione fallisce, l'API restituisce risposte di errore appropriate con dettagli sul fallimento della validazione. Queste risposte includono:

- Il campo che non ha superato la validazione
- Una descrizione del motivo per cui la validazione e fallita
- Eventuali vincoli o formati attesi

Queste informazioni ti aiutano a identificare e risolvere rapidamente i problemi nei dati delle tue richieste.

## Selezione della Lingua

Per le API rivolte all'utente (come il contesto App), le entita restituiranno dati e metadati in una singola lingua. Il meccanismo di selezione della lingua funziona come segue:

1. La lingua viene determinata dal custom claim `lang` nel token di accesso
2. Questo claim viene impostato automaticamente quando un utente effettua l'accesso, in base alle preferenze del suo profilo
3. Tutti i contenuti verranno restituiti nella lingua specificata da questo claim
4. Se il contenuto non e disponibile nella lingua richiesta, potrebbe essere utilizzata una lingua predefinita (tipicamente l'inglese)

> **Importante**: Se un utente modifica la propria preferenza linguistica nel profilo, il token di accesso deve essere aggiornato per recuperare i contenuti nella lingua appena selezionata. La semplice modifica dell'impostazione del profilo senza ottenere un nuovo token non influira sulle risposte delle API.

Questo comportamento si applica a tutti i contenuti traducibili nel sistema, incluse le domande e le risposte dei quiz, i testi dell'interfaccia utente e qualsiasi altra risorsa localizzata.

## Buone Pratiche

1. **Usa le variabili GraphQL** per i valori dinamici anziche l'interpolazione di stringhe
2. **Richiedi solo i campi necessari** per minimizzare la dimensione delle risposte e i tempi di elaborazione
3. **Implementa la gestione degli errori** per gestire in modo elegante i diversi scenari di errore
4. **Usa la pagination** per grandi set di risultati per migliorare le prestazioni
5. **Proteggi gli endpoint** implementando controlli di autorizzazione appropriati
6. **Gestisci l'aggiornamento dei token** quando le preferenze dell'utente cambiano (ad esempio, per assicurarsi che i contenuti vengano forniti nella lingua preferita, che il fuso orario selezionato venga rispettato, ecc.)
