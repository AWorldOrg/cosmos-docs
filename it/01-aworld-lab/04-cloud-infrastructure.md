### Panoramica dell'architettura

AWorld implementa un'architettura cloud-native completamente serverless su Amazon Web Services (AWS), progettata per garantire scalabilità illimitata e alta disponibilità. L'architettura è organizzata in layer funzionali che separano le responsabilità e facilitano l'evoluzione della piattaforma:

- **Account & user layer**: gestione identità, permessi, autenticazione (AWS Cognito) e integrazione server-to-server
- **Gamification layer**: core engine per meccaniche di engagement (missioni, livelli, leaderboard, badge, punti)
- **Catalog layer**: distribuzione e gestione organizzata dei contenuti formativi

L'architettura multi-tenant garantisce rigoroso isolamento dei dati tra clienti, con ogni workspace che opera in completa indipendenza logica pur condividendo l'infrastruttura fisica sottostante per efficienza operativa.

### Stack tecnologico

La piattaforma si basa su servizi AWS, che garantiscono elevati standard di sicurezza, affidabilità e riduzione delle esigenze di manutenzione infrastrutturale.

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

### Database e persistenza dati

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

### Modello multi-tenant con isolamento dati

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

### Distribuzione multi-regione

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

### Vantaggi dell'architettura serverless

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
