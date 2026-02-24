AWorld espone funzionalità tramite API REST con architettura dual-context per separare accessi amministrativi e utente finale.

### API REST

#### Endpoint domains

La piattaforma espone due domini principali per autenticazione e API:

- **Auth domain**: `https://auth.aworld.cloud`
- **API domain (corrente)**: `https://api.eu-west-1.aworld.cloud`
- **API domain (futuro)**: `https://api.aworld.cloud` (migrazione pianificata 1 marzo 2026)

> **Nota**: Durante il periodo di transizione entrambi i domini saranno funzionanti.

#### Due contesti API

Le API sono organizzate in due contesti distinti per separare accessi amministrativi e utente:

**Dashboard API** (`/dashboard/v1/*`):
- **Target**: amministratori e content manager workspace
- **Funzionalità**: gestione missioni, utenti, gruppi, analytics, configurazioni
- **Autorizzazione**: Admin, Editor
- **Endpoint**: 40+ endpoint per gestione piattaforma

**App API** (`/app/v1/*`):
- **Target**: applicazioni end-user (web app, mobile app)
- **Funzionalità**: partecipazione missioni, leaderboard, profilo utente, log attività
- **Autorizzazione**: User, Admin
- **Endpoint**: 30+ endpoint per interazione utente

#### Convenzioni REST

Le API seguono le convenzioni standard REST per coerenza e prevedibilità:

- **HTTP methods**: GET, POST, PUT, PATCH, DELETE
- **Resource naming**: plurale kebab-case (es. `/runtime-leaderboards`)
- **Versioning**: esplicito nella URL (`/v1/`, `/v2/`)
- **ID format**: nanoid (21 caratteri URL-safe)

#### Pattern di integrazione

La piattaforma supporta diversi pattern di integrazione per adattarsi a vari scenari d'uso:

**Client-to-Server (C2S)**:
- Chiamate dirette da frontend (web app, mobile app)
- Autenticazione via token JWT nel header Authorization

**Server-to-Server (S2S)**:
- Chiamate backend con token M2M OAuth2
- User impersonation via header `x-user-id`

**Paginazione**:
- Connection pattern con `limit`, `offset`, `nextToken`
- Evita result set eccessivi

**Idempotency**:
- Header `x-idempotency-key` per prevenzione duplicati
- Cache idempotency keys per 5 minuti

### Pre-provisioning e accesso utenti

> **Nota**: Funzionalità disponibile su richiesta come opzione configurabile per clienti enterprise.

Per minimizzare impatto IT e garantire sicurezza, AWorld supporta flusso di pre-provisioning utenti con accesso passwordless.

#### Setup iniziale (bulk import)

Il processo di pre-provisioning inizia con un caricamento massivo delle utenze autorizzate:

1. Cliente fornisce file CSV con email dipendenti autorizzati
2. AWorld importa utenze nel sistema Cognito workspace dedicato
3. Solo utenti pre-provisioning possono richiedere accesso (whitelist)

#### Gestione continuativa

Dopo il setup iniziale, la gestione degli utenti può avvenire in modalità incrementale:

- **Backoffice amministrazione**: registrazione singoli nuovi utenti
- **Upload liste aggiornate**: import CSV periodici
- **Link dinamico**: funziona immediatamente per nuovi utenti aggiunti

#### Security gate

Il pre-provisioning agisce come un filtro di sicurezza che verifica l'autorizzazione in tempo reale:

- Link condiviso esternamente è inutilizzabile per non autorizzati
- Sistema blocca invio OTP verso indirizzi email non in whitelist
- Pre-provisioning funge da "security gate" per perimetro utenti autorizzati

### Modalità trigger accesso

> **Nota**: Funzionalità disponibile su richiesta come opzione configurabile per clienti enterprise.

#### Opzione A: redirect parametrica (query string)

Questa modalità consente accesso diretto senza sviluppo client-side:

```
https://{accountURL}/login?email={user-email}&autotrigger=true
```

- Email passata come parametro visibile in URL
- Sistema legge parametro, verifica whitelist, invia OTP automaticamente

#### Opzione B: passaggio via custom header

Per scenari che richiedono maggiore privacy, l'email può essere trasmessa tramite header HTTP:

- Cliente effettua richiesta POST verso endpoint login
- Email iniettata in header HTTP concordato (es. `X-AWorld-User-Email`)
- API Gateway configurato per estrarre email da header

### Supporto futuri protocolli

L'architettura è progettata per evoluzione futura con supporto di protocolli moderni come GraphQL.

#### GraphQL-ready architecture

Architettura progettata per supportare GraphQL come layer API aggiuntivo:

- **Maggiore controllo dati**: client richiede solo campi necessari
- **Aggregazione**: informazioni da fonti multiple in singola query
- **Riduzione bandwidth**: ottimizzazione per client mobile
- **Timeline**: roadmap di prodotto 2026-2027

### Single sign-on (SSO) e SAML

#### Supporto nativo Cognito

La piattaforma di autenticazione AWS Cognito offre supporto nativo per protocolli SSO standard:

- **SAML 2.0**: integrazione con identity provider aziendali
- **OpenID Connect (OIDC)**: standard moderno per SSO

#### Integrazione enterprise SSO

Per clienti enterprise con identity provider esistenti, è possibile configurare integrazione SSO dedicata:

- **Identity provider supportati**: Azure AD, Google Workspace
- **Configurazione dedicata**: setup specifico per deployment enterprise
- **Protocolli**: SAML 2.0, OIDC

L'integrazione SSO è particolarmente utile per organizzazioni che desiderano:

- Aziende con identity provider esistente
- Single sign-on per semplificare accesso dipendenti
- Centralizzazione gestione identità

### Middleware stack e gestione errori

La piattaforma utilizza una pipeline di middleware standardizzata basata su Middy per garantire comportamento consistente across tutti gli endpoint API.

#### Middleware Pipeline

Ogni Lambda handler REST è wrappato in middleware stack standardizzato che esegue operazioni trasversali:

**Pipeline Order** (esecuzione sequenziale):
1. **CORS**: Aggiunta headers CORS per cross-origin requests
2. **Inject Lambda Context**: Logger con correlation ID per request tracing end-to-end
3. **M2M Delegation**: User impersonation via `X-User-ID` header (se presente)
4. **Parser**: Validazione Zod di input (path params, query params, body)
5. **Request Logger**: Logging structured della richiesta con parsed input e claims
6. **Handler Execution**: Esecuzione business logic
7. **Response Formatter**: Wrapping risposta in formato API Gateway standard
8. **Error Handler**: Conversione exception in structured error response

**Benefici Middleware Approach**:
- **Consistency**: Comportamento uniforme across tutte le API
- **Separation of concerns**: Cross-cutting concerns separati da business logic
- **Testability**: Ogni middleware testabile indipendentemente
- **Maintainability**: Modifiche centralizzate senza toccare handler individuali

#### Sistema Error Codes Standardizzato

La piattaforma implementa un sistema strutturato di error codes per client error handling robusto:

**Categorie Error Codes**:
- **`auth/*`**: Errori autenticazione/autorizzazione
  - `auth/invalid_token`: Token JWT invalido o malformato
  - `auth/expired_token`: Token expired, refresh necessario
  - `auth/invalid_credentials`: Credenziali errate
  - `auth/insufficient_permissions`: Utente non ha permessi per operazione

- **`validation/*`**: Errori validazione input
  - `validation/invalid_input`: Schema validation failure (Zod)

- **`resource/*`**: Errori resource management
  - `resource/not_found`: Risorsa non trovata (404)
  - `resource/already_exists`: Risorsa già esistente (409)
  - `resource/conflict`: Conflitto stato risorsa

- **`business/*`**: Errori business logic
  - `business/invalid_operation`: Operazione non permessa per stato corrente
  - `business/precondition_failed`: Precondizioni operazione non soddisfatte

- **`rate_limit/*`**: Errori rate limiting
  - `rate_limit/exceeded`: Superato limite richieste

- **`server/*`**: Errori server-side
  - `server/internal_error`: Errore interno generico (500)
  - `server/database_error`: Errore database operation
  - `server/external_service_error`: Errore servizio esterno

**Structured Error Response**:

Ogni errore ritorna response JSON strutturato:

```json
{
  "code": "auth/invalid_token",
  "message": "Token signature is invalid",
  "status": 401,
  "requestId": "abc-123-def-456",
  "timestamp": "2026-02-18T10:30:00Z",
  "path": "/app/v1/missions",
  "url": "https://api.eu-west-1.aworld.cloud/app/v1/missions",
  "docs": "https://docs.aworld.cloud/errors/auth/invalid_token"
}
```

**Idempotency Header Echo**:
- Response include `X-Idempotency-Key` echoed back al client
- Client può verificare che request sia stata processata correttamente
- Utile per debugging e troubleshooting distributed systems
