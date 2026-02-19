# Piattaforma AWorld

**Architettura, sicurezza, conformità e affidabilità**


**Versione**: 1.1
**Data**: 18 febbraio 2026
**Società**: AWorld S.r.l. Società Benefit


## Introduzione

AWorld è una soluzione SaaS enterprise per l'engagement aziendale e la formazione continua attraverso meccaniche di gamification. Il prodotto è costruito sulla piattaforma tecnologica AWorld, un'infrastruttura cloud-native API-first completamente serverless, progettata con approccio security-first e conformità GDPR by design.

Questo documento descrive l'infrastruttura AWorld, le misure di sicurezza implementate, la conformità normativa e le garanzie di affidabilità che costituiscono le fondamenta tecnologiche di AWorld.


## Indice

### [1. Infrastruttura cloud e architettura](#1-infrastruttura-cloud-e-architettura)
- [1.1 Panoramica dell'architettura](#11-panoramica-dellarchitettura)
- [1.2 Stack tecnologico AWS](#12-stack-tecnologico-aws)
- [1.3 Database e persistenza dati](#13-database-e-persistenza-dati)
- [1.4 Modello multi-tenant](#14-modello-multi-tenant-con-isolamento-dati)
- [1.5 Distribuzione multi-regione](#15-distribuzione-multi-regione)
- [1.6 Vantaggi serverless](#16-vantaggi-dellarchitettura-serverless)

### [2. Sicurezza e cybersecurity](#2-sicurezza-e-cybersecurity)
- [2.1 Crittografia dei dati](#21-crittografia-dei-dati)
- [2.2 Protezione delle API](#22-protezione-delle-api)
- [2.3 Autenticazione](#23-autenticazione)
- [2.4 Autorizzazione](#24-autorizzazione)
- [2.5 Struttura token JWT](#25-struttura-token-jwt)
- [2.6 Gestione incidenti](#26-gestione-incidenti-di-sicurezza)

### [3. Compliance e certificazioni](#3-compliance-e-certificazioni)
- [3.1 Conformità GDPR](#31-conformità-gdpr)
- [3.2 Audit e tracciabilità](#32-audit-e-tracciabilità)
- [3.3 Residenza dei dati](#33-residenza-dei-dati)
- [3.4 ISMS](#34-sistema-di-gestione-della-sicurezza-isms)
- [3.5 Conformità contrattuale](#35-conformità-contrattuale)

### [4. Disaster recovery e business continuity](#4-disaster-recovery-e-business-continuity)
- [4.1 Architettura di resilienza](#41-architettura-di-resilienza)
- [4.2 Replica dei dati](#42-replica-dei-dati)
- [4.3 Obiettivi di recupero](#43-obiettivi-di-recupero)
- [4.4 Monitoraggio proattivo](#44-monitoraggio-proattivo)
- [4.5 Procedure di ripristino](#45-procedure-di-ripristino)

### [5. Performance e scalabilità](#5-performance-e-scalabilità)
- [5.1 Metriche di performance](#51-metriche-di-performance)
- [5.2 Scalabilità automatica](#52-scalabilità-automatica)
- [5.3 Strategie di caching](#53-strategie-di-caching-e-storage-media)
- [5.4 Load balancing](#54-load-balancing-e-distribuzione-traffico)
- [5.5 Capacità e limiti](#55-capacità-e-limiti)
- [5.6 Idempotency](#56-idempotency-e-resilienza-operazioni)

### [6. Modalità di accesso e integrazione](#6-modalità-di-accesso-e-integrazione)
- [6.1 API REST](#61-api-rest)
- [6.2 Pre-provisioning utenti](#62-pre-provisioning-e-accesso-utenti)
- [6.3 Modalità trigger](#63-modalità-trigger-accesso)
- [6.4 Futuri protocolli](#64-supporto-futuri-protocolli)
- [6.5 SSO e SAML](#65-single-sign-on-sso-e-saml)
- [6.6 Middleware e errori](#66-middleware-stack-e-gestione-errori)

### Link rapidi tematici
- 🔒 [Autenticazione EMAIL_OTP](#email_otp-passwordless-utenti-finali)
- 🤖 [OAuth2 Machine-to-Machine](#oauth2-client-credentials-machine-to-machine)
- 📊 [Metriche Performance](#51-metriche-di-performance)
- 🌍 [GDPR e Compliance](#31-conformità-gdpr)
- 🔐 [AWS Verified Permissions](#aws-verified-permissions)
- ⚡ [Idempotency](#56-idempotency-e-resilienza-operazioni)


## 1. Infrastruttura cloud e architettura

### 1.1 Panoramica dell'architettura

AWorld implementa un'architettura cloud-native completamente serverless su Amazon Web Services (AWS), progettata per garantire scalabilità illimitata, alta disponibilità e costi ottimizzati. L'architettura è organizzata in layer funzionali che separano le responsabilità e facilitano l'evoluzione della piattaforma:

- **Account & user layer**: gestione identità, permessi, autenticazione (AWS Cognito) e integrazione server-to-server
- **Gamification layer**: core engine per meccaniche di engagement (missioni, livelli, leaderboard, badge, punti)
- **Catalog layer**: distribuzione e gestione organizzata dei contenuti formativi

L'architettura multi-tenant garantisce rigoroso isolamento dei dati tra clienti, con ogni workspace che opera in completa indipendenza logica pur condividendo l'infrastruttura fisica sottostante per efficienza operativa.

### 1.2 Stack tecnologico AWS

La piattaforma si basa su servizi AWS gestiti, che garantiscono elevati standard di sicurezza, affidabilità e riduzione delle esigenze di manutenzione infrastrutturale.

| Componente | Servizio AWS | Funzione |
|------------|--------------|----------|
| **Compute** | AWS Lambda | Esecuzione serverless delle funzioni API |
| **API management** | Amazon API Gateway | Routing, throttling, autenticazione richieste |
| **Database primario** | Amazon DynamoDB | Database NoSQL con chiavi composite tenant-scoped |
| **Database dedicato** | Cloudflare D1 | Database dedicato per indicizzazioni e funzioni applicative specifiche |
| **Caching/Leaderboard** | AWS MemoryDB for Redis | Sistema in-memory per leaderboard real-time |
| **Media storage** | Cloudflare R2 | Storage media con caching automatico e CloudFront ridondato |
| **DNS/routing** | AWS Route 53 | Load balancing geografico multi-regione |
| **Authentication** | AWS Cognito | Gestione identità e user pool |
| **Authorization** | AWS Verified Permissions | Policy-based fine-grained authorization |
| **Feature flags** | AWS AppConfig | Feature flags con safe deployment strategies |
| **Event bus** | Amazon EventBridge | Event-driven architecture multi-region |
| **Configuration** | AWS SSM Parameter Store | Cross-stage configuration management |
| **Monitoring** | AWS CloudWatch | Metriche, log e anomaly detection |
| **Security** | AWS WAF | Web application firewall |

#### Infrastructure as Code

L'intera infrastruttura è definita come codice (Infrastructure as Code) utilizzando SST (Serverless Stack) versione 3 con backend Pulumi, garantendo:

- **Definizione dichiarativa**: Infrastructure scritta in TypeScript per type safety e validazione compile-time
- **Deployment automatizzato**: Processo di deployment riproducibile e versionato
- **Multi-region nativa**: Configurazione dichiarativa per deployment simultaneo su più regioni
- **State management**: Pulumi engine per gestione dello stato infrastrutturale e drift detection
- **Version control**: Tutte le modifiche infrastrutturali passano per code review e CI/CD

Questo approccio elimina configurazioni manuali error-prone e garantisce consistenza tra ambienti di sviluppo, staging e produzione.

### 1.3 Database e persistenza dati

#### Amazon DynamoDB

DynamoDB è il database primario per tutti i dati transazionali e operativi della piattaforma:

- **Modello**: NoSQL con chiavi primarie composite che includono `workspaceId` per isolamento tenant
- **Scaling**: on-demand capacity mode con scaling automatico in base al carico
- **Performance**: latenza single-digit milliseconds per operazioni read/write
- **Partitioning**: automatico per distribuzione del carico
- **Replica**: global tables per sincronizzazione multi-regione in tempo reale

#### Cloudflare D1

Database dedicato affiancato a DynamoDB per assolvere funzioni applicative specifiche:

- **Utilizzo**: indicizzazioni e query complesse
- **Integrazione**: affiancato al database primario per ottimizzare specifiche operazioni

### 1.4 Modello multi-tenant con isolamento dati

AWorld implementa un'architettura multi-tenant con isolamento logico rigoroso che garantisce la completa separazione dei dati tra clienti diversi.

#### Struttura gerarchica

```
Platform (AWorld)
└── Account (cliente/tenant)
    └── Workspace (ambiente: production, staging, dev)
        └── User (utente finale con ruoli specifici)
```

#### Meccanismi di isolamento

**A livello database (DynamoDB)**:
- **Tenant-scoped keys**: ogni record include `workspaceId` come parte della chiave primaria
- **Query filtering automatico**: le query sono automaticamente filtrate per workspace
- **Row-level isolation**: impossibilità fisica di accedere a dati di workspace diversi nella stessa query

**A livello API Gateway**:
- AWS Lambda Authorizer valida ogni richiesta
- Il token JWT contiene il claim `workspaceId` critico per l'isolamento
- Cross-workspace access bloccato prima dell'esecuzione della business logic

**A livello Cognito**:
- User pool condiviso con credenziali isolate per workspace
- App client Cognito dedicato per workspace
- Token JWT workspace-scoped

> **⚠️ Nota critica sicurezza**: Il `workspaceId` nel token JWT è il meccanismo fondamentale per l'isolamento multi-tenant. Ogni richiesta API valida che il `workspaceId` nel token corrisponda al workspace delle risorse richieste, impedendo accessi cross-tenant a livello di API Gateway prima che la richiesta raggiunga il backend.

### 1.5 Distribuzione multi-regione

Per garantire alta disponibilità e disaster recovery, l'infrastruttura AWorld è distribuita su multiple regioni AWS in configurazione active-active.

#### Regioni operative

- **Regione primaria**: `eu-west-1` (Irlanda) - produzione Europa
- **Regione backup**: `eu-north-1` (Stoccolma) - disaster recovery
- **Data residency**: 100% dei dati mantenuti in data center EU per conformità GDPR

#### Load balancing geografico

AWS Route 53 gestisce l'instradamento intelligente del traffico:
- **Geolocation routing**: gli utenti vengono indirizzati alla regione più vicina geograficamente
- **Health checks continui**: monitoraggio continuo dello stato delle regioni
- **Automatic failover**: in caso di guasto regionale, il traffico viene deviato automaticamente verso la regione di backup
- **Latency-based routing**: ottimizzazione automatica per minor latenza

### 1.6 Vantaggi dell'architettura serverless

L'adozione di un'architettura serverless offre benefici significativi in termini operativi e di affidabilità.

#### Scalabilità automatica
- AWS Lambda scala automaticamente in base al volume delle richieste
- Nessun provisioning manuale di server o capacità
- Gestione trasparente di picchi di traffico imprevedibili (es. campagne di engagement aziendali)
- Attivazione istanze aggiuntive in millisecondi

#### Riduzione gestione operativa
- Patching e aggiornamenti gestiti automaticamente
- Zero downtime per manutenzione infrastrutturale
- Focus del team tecnico su sviluppo funzionalità invece di manutenzione server

#### Resilienza intrinseca
- Fault tolerance integrata
- Distribuzione automatica su multiple availability zone
- Riduzione significativa del rischio di single point of failure


## 2. Sicurezza e cybersecurity

### 2.1 Crittografia dei dati

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

### 2.2 Protezione delle API

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

- **Aikido Security**: piattaforma di continuous security monitoring (fonte: ISMS security policies)
- **Rilevamento automatico**: analisi comportamentale del traffico API
- **Alerting real-time**: notifiche immediate su attività sospette
- **Incident response**: attivazione automatica contromisure (es. blocco IP, throttling aggressivo)

#### Gestione vulnerabilità

Sistema strutturato di vulnerability management:

- **Vulnerabilità Critical**: remediation entro ≤ 15 giorni dalla identificazione (fonte: ISMS KPI list)
- **Vulnerabilità High**: remediation entro ≤ 30 giorni dalla identificazione (fonte: ISMS KPI list)
- **Penetration testing**: test di sicurezza semestrali condotti da terze parti (fonte: ISMS security policies)
- **Continuous scanning**: monitoraggio continuo via Aikido Security

### 2.3 Autenticazione

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

### 2.4 Autorizzazione

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

### 2.5 Struttura token JWT

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

### 2.6 Gestione incidenti di sicurezza

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


## 3. Compliance e certificazioni

### 3.1 Conformità GDPR

AWorld è progettato con conformità GDPR integrata dall'architettura.

#### Privacy by design e by default

La privacy è un principio architetturale fondamentale, integrato in ogni livello della piattaforma:

- **Principi integrati**: privacy considerata fin dalla progettazione architetturale
- **Minimizzazione dati**: raccolta solo dati personali strettamente necessari
- **Anonimizzazione e pseudonimizzazione**: tecniche implementate per ridurre esposizione dati sensibili
- **Default sicuri**: configurazioni di default garantiscono protezione dati

#### Diritti degli interessati

Implementazione tecnica per esercizio diritti GDPR:

- **Diritto all'oblio**: cancellazione completa dati utente su richiesta
- **Portabilità dati**: export dati in formato strutturato (JSON)
- **Accesso ai dati**: query completa dati personali associati all'utente
- **Rettifica**: modifica dati personali errati o incompleti
- **Limitazione trattamento**: possibilità di limitare specifici trattamenti

#### Consenso esplicito

La piattaforma implementa meccanismi per garantire che ogni trattamento di dati personali sia basato su consenso informato:

- **Raccolta consenso**: meccanismi per raccolta consenso esplicito al trattamento dati
- **Granularità**: consenso granulare per diverse finalità di trattamento
- **Revoca**: possibilità di revocare consenso in qualsiasi momento

### 3.2 Audit e tracciabilità

La piattaforma implementa un sistema completo di audit logging che garantisce tracciabilità di tutte le operazioni per finalità di compliance e sicurezza.

#### AWS CloudTrail

Il servizio AWS CloudTrail traccia tutte le operazioni di gestione dell'infrastruttura cloud:

- **Copertura**: tutte le chiamate API AWS (gestione infrastruttura)
- **Retention**: log conservati per finalità compliance e audit
- **Immutabilità**: log non modificabili per garantire integrità audit trail

#### Application logs

I log applicativi registrano tutte le operazioni utente per garantire tracciabilità completa:

- **Tracciamento operazioni**: ogni operazione CRUD tracciata
- **Timestamp standardizzati**: ISO 8601 in UTC per tutti gli eventi
- **Metadati**: user ID, workspace ID, IP, user agent per ogni operazione
- **Retention configurabile**: conservazione log in base a requisiti normativi cliente

#### Audit trail

Il sistema mantiene una traccia immutabile di tutti gli eventi critici per la sicurezza e la compliance:

- **Eventi tracciati**:
  - Autenticazione e autorizzazione (login, logout, token refresh)
  - Modifiche configurazione (creazione/modifica missioni, utenti, contenuti)
  - Accesso dati sensibili
  - Modifiche permessi e ruoli
  - Export e download dati

### 3.3 Residenza dei dati

AWorld garantisce data residency in data center europei per assicurare conformità con i requisiti giurisdizionali GDPR.

#### Data center EU

Tutti i dati della piattaforma risiedono esclusivamente in data center situati nell'Unione Europea:

- **Regioni**: eu-west-1 (Irlanda), eu-north-1 (Stoccolma)
- **Copertura**: 100% dati in data center EU (fonte: ISMS KPI list)
- **Garanzia**: dati non transitano fuori dalla regione configurata
- **Compliance**: conformità con requisiti GDPR su trasferimento dati extra-UE

#### Configurazione multi-regione

La piattaforma offre flessibilità nella configurazione geografica dei dati per soddisfare requisiti specifici:

- **Supporto**: possibilità di configurare regioni specifiche per data residency
- **Flessibilità**: deployment dedicati per requisiti giurisdizionali specifici

#### Sub-processors

La gestione dei sub-processors è trasparente e conforme ai requisiti GDPR:

- **Registro**: elenco sub-processors autorizzati e tracciati
- **Conformità**: tutti i sub-processors conformi GDPR
- **Trasparenza**: disponibile documentazione DPA con sub-processors

### 3.4 Sistema di gestione della sicurezza (ISMS)

#### Conformità ISO 27001:2022

AWorld ha implementato un Sistema di Gestione della Sicurezza delle Informazioni (ISMS) conforme allo standard ISO/IEC 27001:2022:

- **Controlli implementati**: controlli di sicurezza ISO 27001 verificati e operativi
- **Statement of Applicability (SoA)**: documento che definisce controlli applicabili
- **Audit interni**: verifiche annuali dell'efficacia dei controlli implementati
- **Certificazione formale**: processo di certificazione in corso

#### Controlli di sicurezza operativi

L'ISMS include controlli operativi verificati e applicati quotidianamente. In particolare, per il controllo degli accessi (fonte: ISMS access control policy):

- MFA obbligatoria su tutti i sistemi critici
- Password minimo 12 caratteri gestite in vault sicuro (Bitwarden)
- Access review semestrali per verifica permessi
- Endpoint encryption obbligatoria (FileVault)

Il sistema di gestione prevede meccanismi di miglioramento continuo:

- Audit interni annuali
- Valutazione rischi periodica
- Aggiornamento controlli in base a nuove minacce

#### AWS Well-Architected Framework

L'architettura della piattaforma segue le best practice definite dai cinque pilastri del AWS Well-Architected Framework:

- **Security**: crittografia, WAF, IAM policies, least privilege
- **Reliability**: multi-AZ, backup, disaster recovery
- **Performance efficiency**: caching, CDN, database optimization
- **Cost optimization**: serverless, auto-scaling, rightsizing
- **Operational excellence**: monitoring, alerting, automation

### 3.5 Conformità contrattuale

#### Data Processing Agreement (DPA)

Per clienti enterprise, AWorld mette a disposizione documentazione contrattuale formale:

- **Disponibilità**: DPA disponibile per clienti enterprise
- **Contenuti**: ruoli e responsabilità nel trattamento dati personali
- **Conformità**: allineamento con requisiti GDPR Articolo 28

#### Service Level Agreement (SLA)

Garanzie formali su uptime e performance:

- **Uptime garantito**: ≥ 99,9% annuale (fonte: ISMS SLA document)
- **Monitoring**: monitoraggio continuo via AWS CloudWatch Application Signals
- **Metriche performance**: API latency ≥ 99% richieste < 1000ms (fonte: ISMS KPI list)
- **Support response times**:
  - P1 (Critico): 4 ore lavorative
  - P2 (Standard): 1 giorno lavorativo
  - P1 Status Updates: ogni 2 ore (100% compliance)


## 4. Disaster recovery e business continuity

### 4.1 Architettura di resilienza

AWorld è progettato per garantire continuità operativa anche in scenari di disaster.

#### Configurazione active-active multi-regione

L'infrastruttura è distribuita geograficamente per garantire resilienza massima:

- **Deployment simultaneo**: servizi attivi contemporaneamente in più regioni AWS
- **No single point of failure**: ogni componente ridondato
- **Replica automatica**: sincronizzazione continua tra regioni

#### Distribuzione componenti

Ogni componente architetturale è replicato per garantire disponibilità continua:

- **Database**: DynamoDB global tables con replica in tempo reale
- **File statici**: sincronizzazione multi-data center
- **API e servizi**: distribuzione su multipli nodi per regione
- **DNS**: Route 53 con health checks e automatic failover

### 4.2 Replica dei dati

La strategia di replica dati garantisce sincronizzazione continua tra regioni e capacità di recovery rapido.

#### Amazon DynamoDB global tables

Il database primario utilizza la tecnologia DynamoDB Global Tables per replica multi-regione:

- **Replica**: tempo reale tra regioni AWS
- **Coerenza**: coerenza eventuale per performance ottimali
- **Latency**: replication lag tipicamente < 1 secondo
- **Failover**: lettura/scrittura possibile su qualsiasi regione

#### Backup automatici

Oltre alla replica real-time, il sistema implementa backup periodici per ulteriore protezione:

- **Frequenza**: backup automatici gestiti da AWS
- **Point-in-time recovery (PITR)**: recupero a qualsiasi punto temporale negli ultimi 35 giorni
- **Retention**: configurabile in base a requisiti cliente

### 4.3 Obiettivi di recupero

Obiettivi formali di disaster recovery testati annualmente.

#### Recovery Time Objective (RTO)

Il Recovery Time Objective definisce il tempo massimo entro cui i servizi devono essere ripristinati:

- **Target**: ≤ 24 ore per ripristino funzioni critiche (fonte: ISMS Business Continuity Plan)
- **Failover automatico**: deviazione traffico via Route 53 senza intervento manuale
- **Regione backup**: eu-north-1 (Stoccolma) pronta per attivazione

#### Recovery Point Objective (RPO)

Il Recovery Point Objective definisce la quantità massima di dati che può essere persa in caso di disaster:

- **Target**: ≤ 1 ora di perdita dati massima in scenari disaster (fonte: ISMS Business Continuity Plan)
- **Replica continua**: database replicati in tempo reale
- **Backup**: point-in-time recovery per minimizzare perdita dati

### 4.4 Monitoraggio proattivo

Un sistema di monitoring continuo consente il rilevamento precoce di anomalie e l'attivazione automatica di contromisure.

#### Metriche di sistema

AWS CloudWatch monitora continuamente lo stato di tutte le risorse infrastrutturali. Le metriche tracciate includono:

- CPU e memoria utilizzo Lambda
- Latenza API Gateway
- Read/write capacity DynamoDB
- Performance MemoryDB
- Error rate API

#### Rilevamento anomalie

Algoritmi di machine learning analizzano i pattern di utilizzo per identificare comportamenti anomali:

- **Automatic anomaly detection**: machine learning per identificazione pattern anomali
- **Event logging**: infrastruttura tracciamento eventi distribuito
- **Threshold alerts**: notifiche automatiche su superamento soglie

#### Contromisure automatiche

Al rilevamento di anomalie, il sistema attiva automaticamente misure correttive:

- **Failover automatico**: verso regione alternativa
- **Auto-scaling**: aumento automatico risorse in caso di picchi
- **Limitazione accessi**: throttling utenti sospetti

### 4.5 Procedure di ripristino

#### Failover automatico DNS

Il processo di failover DNS avviene automaticamente in caso di guasto regionale, seguendo questi step:

1. **Health checks Route 53**: monitoraggio continuo endpoint regionali
2. **Rilevamento guasto**: identificazione automatica regione non disponibile
3. **Deviazione traffico**: DNS update automatico verso regione backup
4. **Propagazione DNS**: tipicamente completata entro minuti
5. **Ripristino trasparente**: nessun impatto percepito dagli utenti

#### Continuità sessioni utente

Le sessioni utente rimangono attive anche durante eventi di failover grazie all'architettura stateless:

- **Token JWT**: indipendenti da regione specifica, validi su tutte le regioni
- **Dati sincronizzati**: replica real-time garantisce continuità operativa
- **Nessuna interruzione**: sessioni utente mantenute durante failover

#### Test disaster recovery

Le procedure di disaster recovery vengono testate regolarmente per garantirne l'efficacia:

- **Frequenza**: simulazioni periodiche scenari di guasto
- **Validazione**: verifica RTO/RPO effettivi
- **Continuous improvement**: affinamento procedure basato su test results


## 5. Performance e scalabilità

### 5.1 Metriche di performance

La piattaforma garantisce obiettivi di performance specifici, monitorati continuamente e formalizzati in SLA.

#### Uptime

La disponibilità del servizio è garantita contrattualmente e monitorata continuamente:

- **Target**: ≥ 99,9% annuale (fonte: ISMS SLA document)
- **Monitoring**: AWS CloudWatch Application Signals
- **Calcolo**: disponibilità misurata su base mensile
- **Esclusioni**: manutenzione programmata comunicata con preavviso

#### API latency

La latenza delle API è ottimizzata per garantire tempi di risposta rapidi:

- **Target**: ≥ 99% richieste completate in < 1000ms (fonte: ISMS KPI list)
- **Monitoring**: percentile p99 tracciato in CloudWatch
- **Ottimizzazione**: caching, query optimization, connection pooling

#### Response time

I tempi di risposta variano in base alla complessità dell'operazione richiesta:

- **Target p95**: < 2 secondi (fonte: ISMS KPI list)
- **Distribuzione**:
  - Operazioni semplici (read): tipicamente < 200ms
  - Operazioni complesse (query aggregate): < 2s

#### Error rate

Il tasso di errore delle API è mantenuto al di sotto di soglie rigorose:

- **Target**: < 0,5% (fonte: ISMS KPI list)
- **Monitoring**: error rate tracciato per endpoint
- **Alerting**: notifiche automatiche su superamento soglia

### 5.2 Scalabilità automatica

#### AWS Lambda

Il layer di compute serverless scala automaticamente senza intervento manuale:

- **Scaling automatico**: in base al volume delle richieste
- **Nessun provisioning manuale**: capacity allocata automaticamente
- **Gestione picchi**: scaling trasparente durante campagne engagement
- **Attivazione rapida**: nuove istanze in millisecondi

#### Amazon DynamoDB

Il database NoSQL è configurato in modalità on-demand per adattarsi dinamicamente al carico:

- **On-demand mode**: scaling automatico read/write capacity
- **Partitioning automatico**: distribuzione carico per performance consistenti
- **Throughput illimitato**: capacità teoricamente illimitata (costi proporzionali)

### 5.3 Strategie di caching e storage media

Il sistema è ottimizzato per garantire performance elevate attraverso caching intelligente e storage distribuito dei contenuti multimediali.

#### AWS MemoryDB for Redis

Database in-memory per funzionalità che richiedono accesso ultra-rapido ai dati:

- **Utilizzo principale**: gestione leaderboard in tempo reale
- **Performance**: latenza sub-millisecondo per operazioni read/write
- **Persistenza**: durabilità garantita con snapshot e transaction log
- **Multi-AZ**: replica automatica per alta disponibilità

I vantaggi dell'utilizzo di MemoryDB includono:

- Aggiornamenti leaderboard in tempo reale senza latenza
- Supporto operazioni atomiche per ranking e scoring
- Scalabilità orizzontale per carichi elevati

#### Cloudflare R2 per media storage

Storage primario per contenuti multimediali con caching automatico integrato:

- **Storage**: contenuti media (immagini, video, documenti)
- **Caching automatico**: edge caching distribuito globalmente
- **CloudFront integration**: ridondanza automatica tramite CloudFront CDN
- **Accesso ottimizzato**: contenuti serviti da location geograficamente prossime agli utenti

Questa soluzione offre benefici significativi:

- Riduzione latency per download contenuti multimediali
- Riduzione carico sui server applicativi
- Costi ottimizzati per storage e bandwidth
- Distribuzione geografica automatica dei contenuti

### 5.4 Load balancing e distribuzione traffico

#### AWS Route 53

Il servizio DNS gestisce l'instradamento intelligente del traffico tra le regioni:

- **Geolocation routing**: utenti indirizzati alla regione più vicina
- **Latency-based routing**: ottimizzazione per minor latency network
- **Health checks continui**: monitoraggio stato endpoint regionali
- **Automatic failover**: deviazione traffico in caso di guasto regionale

#### AWS Lambda distribution

Il carico computazionale è distribuito automaticamente tra istanze multiple:

- **Bilanciamento automatico**: carico distribuito su multipli nodi Lambda
- **Distribuzione equa**: allocazione intelligente esecuzioni
- **Gestione concorrenza elevata**: nessun bottleneck per picchi traffico

### 5.5 Capacità e limiti

#### Rate limiting configurabile

Il sistema implementa controlli sul rate delle richieste per garantire equità e protezione:

- **Per tenant**: policy throttling workspace-specific
- **Prevenzione abusi**: protezione da utilizzo eccessivo
- **Fair usage**: garanzia equità risorse in ambiente multi-tenant

#### Limiti default API Gateway

Configurabili su richiesta per clienti enterprise:
- **Timeout richiesta**: 29 secondi (limite AWS API Gateway)
- **Payload size**: 6MB max per richiesta
- **Throttling**: dinamico basato su piano cliente

### 5.6 Idempotency e resilienza operazioni

Per garantire resilienza in scenari di retry e network instability, la piattaforma implementa idempotency nativa tramite AWS Lambda Powertools:

**AWS Lambda Powertools Idempotency**:
- **Persistence**: DynamoDB table dedicata per storage idempotency keys
- **Header support**: `X-Idempotency-Key` fornito da client per operazioni critiche
- **Auto-generation**: Se header non fornito, Powertools genera key automaticamente da body + path parameters
- **TTL management**: Keys expire automaticamente dopo completion con cleanup automatico
- **Response caching**: Risposta originale cached e returned immediatamente per duplicate requests

**Middleware Integration**:

Il middleware idempotency è integrato automaticamente nella pipeline di ogni endpoint write:

```
Request → CORS → Logger → M2M Delegation → Parser → Idempotency Check → Handler
                                                          ↓
                                                    DynamoDB Cache
                                                          ↓
                                        (if duplicate) → Return Cached Response
```

**Benefici**:
- **Network retry safety**: Client può ritentare richieste POST/PUT/PATCH senza rischio duplicati
- **Distributed system resilience**: Gestione failure parziali in sistemi distribuiti
- **Audit compliance**: Ogni operazione tracciata univocamente con idempotency key
- **Performance**: Duplicate requests resolve in ~10ms (DynamoDB read) vs full execution
- **Developer experience**: Idempotency trasparente, no codice custom necessario

**Use Cases**:
- Creazione risorse (missioni, utenti, contenuti)
- Operazioni finanziarie (assegnazione punti, virtual currency)
- Operazioni batch con possibili retry
- Mobile apps con connectivity instabile


## 6. Modalità di accesso e integrazione

AWorld espone funzionalità tramite API REST con architettura dual-context per separare accessi amministrativi e utente finale.

### 6.1 API REST

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

### 6.2 Pre-provisioning e accesso utenti

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

### 6.3 Modalità trigger accesso

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

### 6.4 Supporto futuri protocolli

L'architettura è progettata per evoluzione futura con supporto di protocolli moderni come GraphQL.

#### GraphQL-ready architecture

Architettura progettata per supportare GraphQL come layer API aggiuntivo:

- **Maggiore controllo dati**: client richiede solo campi necessari
- **Aggregazione**: informazioni da fonti multiple in singola query
- **Riduzione bandwidth**: ottimizzazione per client mobile
- **Timeline**: roadmap di prodotto 2026-2027

### 6.5 Single sign-on (SSO) e SAML

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

### 6.6 Middleware stack e gestione errori

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


## Appendice A: Glossario tecnico

### Termini architetturali

**Active-active**: configurazione multi-regione dove tutte le regioni sono operative simultaneamente.

**Multi-tenant**: architettura dove più clienti (tenant) condividono la stessa infrastruttura con isolamento logico.

**Serverless**: modello architetturale dove il cloud provider gestisce automaticamente allocazione risorse senza provisioning manuale server.

**Workspace**: ambiente isolato per un cliente (production, staging, dev).

### Termini sicurezza

**ABAC (Attribute-Based Access Control)**: controllo accessi basato su attributi dinamici dell'utente e contesto.

**JWT (JSON Web Token)**: standard per token di autenticazione/autorizzazione che contiene claims firmati crittograficamente.

**MFA (Multi-Factor Authentication)**: autenticazione che richiede multiple forme di verifica identità.

**OTP (One-Time Password)**: password usa-e-getta valida per singola sessione o transazione.

**RBAC (Role-Based Access Control)**: controllo accessi basato su ruoli predefiniti con permessi statici.

**WAF (Web Application Firewall)**: firewall che ispeziona traffico HTTP per bloccare attacchi web.

### Termini compliance

**DPA (Data Processing Agreement)**: accordo che definisce ruoli e responsabilità nel trattamento dati personali.

**GDPR (General Data Protection Regulation)**: regolamento europeo sulla protezione dati personali.

**ISMS (Information Security Management System)**: sistema di gestione sicurezza informazioni secondo ISO 27001.

**Privacy by Design**: principio che integra privacy fin dalla progettazione sistemi.

**RPO (Recovery Point Objective)**: quantità massima di dati che può essere persa in disaster scenario.

**RTO (Recovery Time Objective)**: tempo massimo per ripristinare servizio dopo disaster.

### Termini operativi

**Failover**: processo automatico di passaggio a sistema backup in caso di guasto primario.

**Health check**: monitoraggio automatico stato servizi per rilevamento guasti.

**Throttling**: limitazione rate richieste per prevenire abusi e garantire fair usage.