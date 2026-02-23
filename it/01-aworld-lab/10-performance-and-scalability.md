### Metriche di performance

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

### Scalabilità automatica

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

### Strategie di caching e storage media

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

### Load balancing e distribuzione traffico

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

### Capacità e limiti

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

### Idempotency e resilienza operazioni

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
