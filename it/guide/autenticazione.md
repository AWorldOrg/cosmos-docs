# Autenticazione & Autorizzazione

Questa guida spiega come funzionano l'autenticazione e l'autorizzazione nella piattaforma Cosmos.

## Panoramica

Cosmos utilizza AWS Cognito con un dominio personalizzato per l'autenticazione, implementando i flussi standard OAuth2. La piattaforma supporta sia l'autenticazione incentrata sull'utente che l'autorizzazione machine-to-machine (M2M) attraverso client credentials.

## Metodi di Autenticazione

### Autenticazione Utente (OAuth2)

Per le applicazioni incentrate sull'utente, Cosmos implementa il flusso standard di authorization code OAuth2:

1. **Richiesta di Autorizzazione**: Il client reindirizza l'utente all'endpoint di autorizzazione Cognito
2. **Autenticazione Utente**: L'utente si autentica con le proprie credenziali
3. **Codice di Autorizzazione**: Dopo l'autenticazione riuscita, il server di autorizzazione reindirizza con un codice di autorizzazione
4. **Scambio di Token**: Il client scambia il codice di autorizzazione per ottenere token di accesso e refresh
5. **Accesso API**: Il client utilizza il token di accesso per effettuare richieste API autenticate

### Autenticazione Machine-to-Machine (Client Credentials)

Per le interazioni M2M, Cosmos supporta il flusso client credentials di OAuth2:

1. **Richiesta di Token**: Il client effettua una richiesta diretta all'endpoint token con client ID e secret
2. **Risposta Token**: Il server di autorizzazione restituisce i token di accesso
3. **Accesso API**: Il client utilizza il token di accesso per effettuare richieste API autenticate

## Tipi di Token

### Access Token

- Utilizzato per accedere a risorse e API protette
- Formato JWT contenente claims sull'utente o client autenticato
- Breve durata (tipicamente 1 ora)
- Deve essere incluso nelle richieste API come Bearer token nell'header Authorization

### Refresh Token

- Utilizzato per ottenere nuovi access token quando scadono
- Lunga durata (tipicamente 30 giorni)
- Deve essere conservato in modo sicuro dal client
- Non può essere utilizzato direttamente per accedere alle risorse protette

### ID Token

- Contiene informazioni sull'identità dell'utente
- Formato JWT
- Utilizzato dall'applicazione client per verificare l'identità dell'utente
- Non destinato all'autorizzazione API

## Endpoint di Autenticazione

| Endpoint | Descrizione |
|----------|-------------|
| `https://auth.aworld.cloud/oauth2/authorize` | Endpoint di autorizzazione per iniziare i flussi OAuth2 |
| `https://auth.aworld.cloud/oauth2/token` | Endpoint token per ottenere i token di accesso |
| `https://auth.aworld.cloud/oauth2/userInfo` | Endpoint userInfo per ottenere i dettagli dell'utente |

## Contesti Utente e Livelli di Accesso

### Principal (Utente a livello di Piattaforma)

I Principal hanno accesso attraverso gli account e tipicamente rappresentano amministratori o super-utenti.

### User (Utente a livello di Workspace)

Gli User sono limitati a uno specifico workspace all'interno di un account, con permessi limitati al workspace assegnato.

## Integrazione con l'Autenticazione Cosmos

### Applicazioni Web

Per le applicazioni web, raccomandiamo di utilizzare il flusso authorization code con PKCE (Proof Key for Code Exchange):

```javascript
// Esempio di richiesta di autorizzazione
const authorizationUrl = new URL('https://auth.aworld.cloud/oauth2/authorize');
authorizationUrl.searchParams.append('client_id', 'YOUR_CLIENT_ID');
authorizationUrl.searchParams.append('response_type', 'code');
authorizationUrl.searchParams.append('redirect_uri', 'YOUR_REDIRECT_URI');
authorizationUrl.searchParams.append('scope', 'openid profile email');
authorizationUrl.searchParams.append('state', 'YOUR_STATE_VALUE');
authorizationUrl.searchParams.append('code_challenge', 'YOUR_CODE_CHALLENGE');
authorizationUrl.searchParams.append('code_challenge_method', 'S256');

// Reindirizza l'utente all'URL di autorizzazione
window.location.href = authorizationUrl.toString();
```

### Applicazioni Mobile

Le applicazioni mobile dovrebbero utilizzare anche il flusso authorization code con PKCE, tipicamente usando un browser di sistema o una scheda browser in-app.

### Applicazioni Server-side

Le applicazioni server-side possono utilizzare il flusso client credentials:

```javascript
// Esempio di richiesta token
const tokenResponse = await fetch('https://auth.aworld.cloud/oauth2/token', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: new URLSearchParams({
    grant_type: 'client_credentials',
    client_id: 'YOUR_CLIENT_ID',
    client_secret: 'YOUR_CLIENT_SECRET',
    scope: 'YOUR_SCOPES',
  }),
});

const tokens = await tokenResponse.json();
// Utilizza tokens.access_token per le richieste API
```

## Best Practices

1. **Mai esporre client secrets** in applicazioni pubbliche (utilizzare invece authorization code flow con PKCE)
2. **Validare sempre i token** prima di fidarsi del loro contenuto
3. **Conservare i refresh token in modo sicuro** per prevenire accessi non autorizzati
4. **Implementare il rinnovo dei token** per gestire la scadenza dei token
5. **Utilizzare HTTPS** per tutte le richieste relative all'autenticazione
6. **Implementare una corretta gestione degli errori** per i fallimenti di autenticazione
7. **Limitare le richieste di scope** solo a ciò di cui la tua applicazione ha bisogno
8. **Implementare un corretto logout** per ripulire sessioni e token

## Problemi Comuni e Risoluzione

### Token non Valido

Se ricevi un errore "Invalid token", il token potrebbe essere scaduto o essere stato manomesso. Richiedi un nuovo access token utilizzando il tuo refresh token.

### Grant non Valido

Questo tipicamente si verifica quando si tenta di utilizzare un codice di autorizzazione più di una volta o quando si utilizza un refresh token scaduto.

### Client non Autorizzato

Questo errore indica che il client non ha il permesso di utilizzare il tipo di grant o gli scope richiesti.

## Risorse Aggiuntive

- [Specifiche OAuth 2.0](https://oauth.net/2/)
- [Documentazione AWS Cognito](https://docs.aws.amazon.com/cognito/latest/developerguide/what-is-amazon-cognito.html)
- [JWT.io](https://jwt.io/) - Per il debug dei JSON Web Token
