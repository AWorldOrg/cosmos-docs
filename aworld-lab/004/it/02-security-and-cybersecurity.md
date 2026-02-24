### Crittografia dei dati

AWorld implementa crittografia end-to-end per proteggere i dati sia in transito che a riposo, utilizzando standard industriali riconosciuti.

#### Crittografia in transito

Tutte le comunicazioni tra client e server sono protette mediante protocolli di crittografia standard:

- **Protocollo**: TLS 1.2 e TLS 1.3 obbligatori per tutte le comunicazioni API
- **Copertura**: 100% dei flussi di dati tra client e server (verificato via AWS Config con audit semestrali)
- **Certificati**: gestiti tramite AWS Certificate Manager con rinnovo automatico
- **Benefici**: protezione contro attacchi man-in-the-middle, intercettazione dati, downgrade attacks

#### Crittografia a riposo

I dati memorizzati su storage persistente sono protetti mediante crittografia con gestione centralizzata delle chiavi:

- **Algoritmo**: AES-256 per tutti i dati su storage persistente
- **Copertura**: 100% dei dati in Amazon DynamoDB e storage (verificato via AWS Config con audit semestrali)
- **Key management**: AWS Key Management Service (KMS) per gestione centralizzata chiavi
- **Rotazione chiavi**: automatica secondo policy AWS
- **Benefici**: protezione dati in caso di accesso fisico non autorizzato ai data center

### Protezione delle API

La protezione delle API si articola su più livelli di difesa complementari.

#### AWS WAF (web application firewall)

AWorld utilizza AWS WAF con configurazione dual-layer per protezione completa:

**Configurazione WAF**:
- **Cognito Pool WAF** (scope REGIONAL): Protegge Cognito User Pool da attacchi diretti
- **Auth Proxy WAF** (scope CLOUDFRONT): Protegge CloudFront distribution per Cognito Proxy Router
- **CloudWatch metrics**: Abilitato per monitoring e alerting in tempo reale

**Regole di protezione**:
- **Rate limiting aggressivo**: 100 richieste per finestra di 5 minuti per IP address
- **SQL injection**: Blocco pattern di query SQL malevole
- **Cross-site scripting (XSS)**: Filtri per prevenire injection di script dannosi
- **AWS Managed Rules**: Amazon IP Reputation List per blocco automatico IP malevoli noti
- **Sampled requests**: Logging richieste bloccate per analisi post-incidente

#### Rate limiting e throttling

Per prevenire abusi e garantire equità nell'allocazione delle risorse:

- **Throttling API Gateway**: limiti configurabili per endpoint
- **Burst capacity**: gestione controllata di picchi temporanei
- **Fair usage**: garanzia di risorse per tutti i tenant in ambiente multi-tenant

#### Protezione DDoS

La piattaforma è protetta nativamente contro attacchi distribuiti di negazione del servizio:

- **AWS Shield Standard**: protezione automatica contro attacchi DDoS comuni (inclusa in API Gateway)
- **Rate limiting distribuito**: mitigazione automatica di pattern di attacco
- **Scaling automatico**: assorbimento del traffico di attacco senza impatto sui clienti legittimi

#### Monitoraggio minacce continuo

Un sistema di monitoring attivo analizza costantemente il traffico per identificare e bloccare attività sospette:

- **Monitoraggio continuo della sicurezza**: piattaforma dedicata per il rilevamento delle minacce in tempo reale (fonte: ISMS security policies)
- **Rilevamento automatico**: analisi comportamentale del traffico API
- **Alerting real-time**: notifiche immediate su attività sospette
- **Incident response**: attivazione automatica contromisure (es. blocco IP, throttling aggressivo)

#### Gestione vulnerabilità

Sistema strutturato di vulnerability management:

- **Vulnerabilità Critical**: remediation entro ≤ 15 giorni dalla identificazione (fonte: ISMS KPI list)
- **Vulnerabilità High**: remediation entro ≤ 30 giorni dalla identificazione (fonte: ISMS KPI list)
- **Penetration testing**: test di sicurezza semestrali condotti da terze parti (fonte: ISMS security policies)
- **Continuous scanning**: monitoraggio automatizzato delle vulnerabilità tramite piattaforma di sicurezza dedicata

### Autenticazione

AWorld supporta multiple modalità di autenticazione per diversi use case.

#### EMAIL_OTP passwordless (utenti finali)

Autenticazione senza password per utenti finali, che riduce la superficie di attacco e semplifica l'esperienza utente.

**Flusso di autenticazione**:

1. **Richiesta OTP**:
   - L'utente inserisce la propria email
   - AWS Cognito genera un one-time password (OTP) a 6 cifre
   - L'OTP viene inviato via email all'utente
   - Cognito restituisce un session token temporaneo

2. **Verifica OTP**:
   - L'utente inserisce l'OTP ricevuto via email
   - Il sistema valida l'OTP insieme al session token
   - Se valido, Cognito restituisce: access token, ID token, refresh token

**Scadenze**:
- **OTP**: 3 minuti
- **Session token**: 3 minuti
- **Access token**: 1 ora
- **Refresh token**: 30 giorni (non cambia al refresh)

**Vantaggi sicurezza**:
- Nessuna password da memorizzare o gestire
- OTP single-use e a scadenza breve
- Riduzione superficie di attacco (no credential stuffing, no password reuse)
- SECRET_HASH HMAC-SHA256 per validazione client con secret

#### OAuth2 client credentials (machine-to-machine)

Standard OAuth2 per autenticazione di servizi backend e integrazioni server-to-server.

**Flusso di autenticazione**:

1. Client autentica con `client_id` e `client_secret` (Basic Auth)
2. Richiesta a `https://auth.aworld.cloud/oauth2/token` con `grant_type=client_credentials`
3. Risposta contiene `access_token` con scope configurati

**Scope disponibili**:
- `app/read`: lettura dati end-user API
- `app/write`: scrittura dati end-user API (es. log attività per conto utente)
- `dashboard/read`: lettura configurazioni e analytics
- `dashboard/write`: creazione/modifica missioni, contenuti, utenti

**User impersonation**:
- Token M2M può operare per conto di utenti specifici
- Header `x-user-id` per specificare utente da impersonare
- Utile per operazioni batch che devono risultare come azioni utente

#### Cognito Proxy Router

Per ottimizzare costi e performance delle chiamate OAuth2, la piattaforma implementa un proxy intelligente che riduce drasticamente le richieste verso Cognito:

**Architettura**:
- **CloudFront distribution**: Custom domain `auth.{CUSTOM_DOMAIN}` con routing selettivo
- **Lambda@Edge**: Routing intelligente per endpoint specifici
- **DynamoDB caching**: Storage persistente per token M2M

**Funzionalità token caching**:

La piattaforma implementa caching sofisticato per il flusso OAuth2 Client Credentials:

- **Cache key**: SHA-256 hash di Authorization header + scope (no plaintext secrets in database)
- **Storage**: DynamoDB con chiavi hashed per sicurezza
- **TTL strategy**: Dual TTL approach
  - Runtime validation: Controlla `expiresAt > now` prima del return
  - DynamoDB TTL: Background cleanup automatico dei token expired
- **TTL ratio**: Configurabile (default 75% della token expiry, es. token 1h → cache 45min)

**Routing intelligente**:
- `/oauth2/token` → Lambda (con caching logic per client_credentials)
- `/.well-known/openid-configuration` → Lambda (cached response con URL rewriting)
- Altri path → Pass-through diretto a Cognito

**Benefici**:
- Riduzione drastica chiamate a Cognito per operazioni M2M ripetute
- Ottimizzazione costi (ogni chiamata Cognito ha un costo)
- Performance migliorata (risposta da cache in ~10ms vs ~100ms Cognito)
- Security: Secrets mai memorizzati in plaintext

### Autorizzazione

#### Lambda Authorizer

Meccanismo di autorizzazione dinamica per ogni singola richiesta API:

- **Validazione token JWT**: verifica firma, scadenza, issuer
- **Validazione workspaceId**: confronto tra `workspaceId` nel token e workspace richiesto
- **Isolamento tenant**: blocco accessi cross-workspace a livello API Gateway
- **Performance**: risultati cacheable per ridurre latenza

#### RBAC (role-based access control)

Modello di controllo accessi basato su ruoli predefiniti:

- **Owner**: massimo livello di controllo, gestione configurazioni workspace
- **Admin**: configurazione piattaforma, gestione utenti, accesso completo
- **Manager**: gestione operativa, creazione e modifica contenuti
- **Member**: accesso standard alle funzionalità
- **Viewer**: accesso in sola lettura a dati e analytics

Permessi statici assegnati per ruolo, semplificando la gestione degli accessi.

#### ABAC (attribute-based access control)

Evoluzione verso controllo accessi basato su attributi per maggiore flessibilità:

- **Permessi dinamici**: basati su attributi utente (es. status Premium, department, location)
- **Condizioni contestuali**: orario, stato completamento, proprietà risorse
- **Maggiore granularità**: regole più flessibili rispetto a RBAC statico
- **Scalabilità**: riduzione necessità di gestire manualmente ruoli multipli

#### AWS Verified Permissions

La piattaforma utilizza AWS Verified Permissions per authorization policy-based fine-grained, separando completamente la logica di autorizzazione dal codice applicativo:

**Policy Store Configuration**:
- **Policy Store**: Repository centralizzato di policies authorization
- **Identity Source**: Integrazione con Cognito via OIDC con custom claim `identityId` come principal
- **Schema Entities**: Definizione di entity types (Identity, User, Resources) e Actions
- **Validation**: Policy validation engine per prevenire errori di configurazione

**Integration Flow**:

Il Lambda Authorizer integra Verified Permissions per decision-making:

1. API Gateway riceve richiesta con JWT token
2. Lambda Authorizer estrae token e parametri (path, query)
3. Chiamata a `IsAuthorizedWithToken` API di Verified Permissions
4. Decision engine valuta policies con context attributes
5. Risposta (Allow/Deny) trasformata in IAM policy per API Gateway
6. Request autorizzata o bloccata a livello gateway

**Context-Aware Authorization**:
- **Path parameters**: `workspaceId`, `resourceId` estratti dalla URL
- **Query parameters**: Filtri e condizioni passati come context
- **Custom attributes**: Claims JWT (role, platform, context) valutati nelle policies

**Vantaggi**:
- **Centralizzazione**: Policies gestite centralmente, non sparse nel codice
- **Auditability**: Ogni decisione authorization tracciata e auditable
- **ABAC nativo**: Attribute-based access control oltre a role-based
- **Scalabilità**: Aggiunta nuovi resource types senza modifiche codice applicativo
- **Testing**: Policies testabili indipendentemente dall'applicazione

### Struttura token JWT

#### Access token (TTL: 1 ora)

Token utilizzato per autorizzare richieste API.

| Claim | Descrizione | Importanza sicurezza |
|-------|-------------|----------------------|
| `sub` | Cognito user ID | Identificativo univoco utente |
| `workspaceId` | Workspace ID | **CRITICO**: Isolamento multi-tenant |
| `accountId` | Account ID | Tenant di appartenenza |
| `userId` | Application user ID | ID utente applicativo |
| `context` | `"dashboard"` \| `"app"` | Contesto API autorizzato |
| `platform` | `"web"` \| `"mobile"` \| `"m2m"` | Tipo client |
| `role` | Ruolo utente | Permessi RBAC |
| `exp` | Unix timestamp | Scadenza token |

**Refresh Token** (TTL: 30 giorni):

- Token opaco (non JWT) utilizzato per ottenere nuovi access token senza riautenticazione
- **Non cambia al refresh**: rimane valido fino a scadenza 30 giorni
- Quando scade, l'utente deve riautenticarsi

#### M2M Delegation con User Impersonation

I client machine-to-machine possono opzionalmente operare per conto di utenti specifici, mantenendo audit trail completo:

**Meccanismo**:
- Client M2M ottiene access token con `platform: "m2m"`
- Per operazioni per conto utente, client passa header `X-User-ID: {userId}`
- Middleware `m2mDelegation` intercetta header e valida:
  - Esistenza utente nel workspace
  - Membership utente nel workspace corrente
  - Permessi delegati dal token M2M

**Claims Enrichment**:
Il middleware arricchisce i claims originali M2M con informazioni utente:
- `userId`: ID utente da impersonare
- `principalId`: Principal ID utente
- `lang`, `timezone`: Preferenze utente

**Use Cases**:
- **Import bulk dati**: Sincronizzazioni da sistemi HR/LMS dove ogni operazione deve apparire come azione dell'utente reale
- **Operazioni batch**: Automazioni che devono mantenere ownership corretta dei dati
- **Audit trail**: Tracciabilità operazioni con utente reale, non solo service account
- **GDPR compliance**: Export dati per conto utente specifico

**Security**:
- Token M2M deve avere scope `app/write` o `dashboard/write`
- Validazione workspace membership obbligatoria
- Rate limiting applicato sia a livello M2M client che utente impersonato

### Gestione incidenti di sicurezza

Piano strutturato di incident response per gestione anomalie e violazioni di sicurezza:

#### Identificazione e isolamento

La prima fase della risposta a incidenti si concentra sul contenimento rapido della minaccia:

- **Rilevamento automatico**: sistemi di monitoring identificano attività sospette
- **Isolamento immediato**: attività sospette isolate automaticamente
- **Blocco preventivo**: IP o utenti sospetti bloccati temporaneamente

#### Alerting e notifica

Il sistema garantisce comunicazione tempestiva degli incidenti a tutti gli stakeholder coinvolti:

- **Alert in tempo reale**: notifiche ai responsabili sicurezza
- **Notifica incidenti**: notifica agli interessati entro 72 ore dalla conferma (fonte: ISMS security policies)
- **Escalation strutturata**: procedure di escalation in base a severity

#### Analisi e risposta

Ogni incidente viene analizzato approfonditamente per prevenire ricorrenze future:

- **Root cause analysis**: analisi approfondita della causa dell'incidente
- **Misure correttive**: implementazione fix per prevenzione eventi futuri
- **Documentazione**: tracciamento completo incident per compliance

#### Continuità operativa

Anche durante la gestione di incidenti di sicurezza, la piattaforma mantiene la continuità del servizio:

- **Failover automatico**: deviazione traffico verso regioni alternative in caso di attacco
- **Business continuity**: mantenimento servizio anche durante incident response
