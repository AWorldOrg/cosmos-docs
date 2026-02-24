### Conformità GDPR

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

### Audit e tracciabilità

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

### Residenza dei dati

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

### Sistema di gestione della sicurezza (ISMS)

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

### Conformità contrattuale

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
