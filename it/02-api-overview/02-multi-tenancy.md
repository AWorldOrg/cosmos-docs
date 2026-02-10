## Cos'e' la Multi-tenancy?

La multi-tenancy e' un'architettura software in cui una singola istanza di software serve piu' clienti o "tenant". I dati e la configurazione di ciascun tenant rimangono isolati da quelli degli altri tenant, anche se condividono l'infrastruttura e il codice applicativo sottostanti.

Nella piattaforma AWorld, un **Account** rappresenta un tenant, ovvero tipicamente un'organizzazione o un'azienda che utilizza la piattaforma.

## Architettura Multi-tenant in AWorld

La piattaforma AWorld implementa un'architettura multi-tenant gerarchica:

```
Platform
└── Account (Tenant)
    └── Workspace
        └── User
```

### Componenti Principali

- **Platform**: Il sistema AWorld di livello superiore che ospita tutti gli account
- **Account**: Un tenant con i propri dati e configurazione isolati
- **Workspace**: Un ambiente all'interno di un account (ad es. sviluppo, staging, produzione)
- **User**: Un utente a livello di workspace con permessi specifici
- **Principal**: Un utente a livello di piattaforma che puo' operare tra account e workspace diversi

## Isolamento del Tenant

La piattaforma AWorld garantisce l'isolamento del tenant a piu' livelli:

### Isolamento dei Dati

I dati di ciascun account sono logicamente isolati dagli altri account. Questo isolamento garantisce che:

- Un tenant non possa accedere ai dati di un altro tenant
- I problemi nell'ambiente di un tenant non influenzino gli altri
- Ogni tenant possa avere configurazioni personalizzate

### Autenticazione e Autorizzazione

La piattaforma utilizza AWS Cognito con un dominio personalizzato per l'autenticazione, fornendo:

- Flussi di autenticazione specifici per tenant
- Gestione degli utenti all'interno di ciascun account
- Controllo degli accessi basato sui ruoli sia a livello di account che di workspace

### Accesso alle API

Tutte le chiamate API sono autenticate e limitate al contesto del tenant appropriato:

- Le API in contesto App operano all'interno di un workspace specifico, offrendo funzionalita' rivolte agli utenti
- Le API in contesto Dashboard operano all'interno di un workspace specifico, offrendo funzionalita' di gestione e osservabilita'
- Le API in contesto Portal possono operare tra account e workspace diversi (solo per i principal)

## Vantaggi della Multi-tenancy

L'architettura multi-tenant di AWorld offre diversi vantaggi:

### Per i Fornitori di Servizi

- **Efficienza Operativa**: Gestire una singola istanza software e' piu' efficiente rispetto alla gestione di istanze separate per ogni cliente
- **Ottimizzazione delle Risorse**: L'infrastruttura condivisa porta a un miglior utilizzo delle risorse
- **Manutenzione Semplificata**: Aggiornamenti e miglioramenti vanno a beneficio di tutti i tenant contemporaneamente
- **Riduzione dei Costi**: Costi operativi inferiori rispetto ai deployment single-tenant

### Per i Tenant (Account)

- **Onboarding Rapido**: Configurazione veloce senza provisioning di infrastruttura complessa
- **Aggiornamenti Automatici**: Accesso costante alle funzionalita' e alle patch di sicurezza piu' recenti
- **Scalabilita'**: L'infrastruttura si adatta alle esigenze di utilizzo
- **Flessibilita' del Workspace**: Possibilita' di creare ambienti isolati multipli all'interno di un account

## Considerazioni sulla Sicurezza

Sebbene la multi-tenancy offra molti vantaggi, richiede anche un'implementazione attenta della sicurezza:

- **Autenticazione**: Verifica dell'identita' robusta per garantire che gli utenti accedano solo ai propri account autorizzati
- **Autorizzazione**: Controlli granulari dei permessi per limitare l'accesso all'interno degli account
- **Isolamento dei Dati**: Confini rigorosi tra i dati dei tenant
- **Logging e Auditing**: Tracciamento completo delle attivita' per rilevare tentativi di accesso non autorizzati

## Utilizzo delle API Multi-tenant

Quando si interagisce con le API di AWorld, il contesto del tenant viene stabilito tramite l'autenticazione:

1. **Autenticazione dell'Utente**: Al momento del login, l'utente viene associato a un workspace e un account specifici
2. **Token di Accesso**: Il token JWT contiene le dichiarazioni sull'identita' dell'utente e gli ambiti del tenant consentiti
3. **Richieste API**: Tutte le chiamate API includono il token di accesso, che determina il contesto del tenant

## Best Practice per le Operazioni Multi-tenant

### Per gli Amministratori della Piattaforma

- Eseguire audit regolari dei meccanismi di isolamento dei tenant
- Monitorare potenziali vulnerabilita' di accesso tra tenant
- Implementare il rate limiting per evitare che un tenant monopolizzi le risorse
- Garantire procedure adeguate di backup e disaster recovery per tutti i tenant

### Per gli Amministratori degli Account

- Implementare una strategia chiara di workspace per i diversi ambienti
- Verificare regolarmente i permessi di accesso degli utenti
- Utilizzare workspace separati per sviluppo e produzione
- Seguire il principio del privilegio minimo nell'assegnazione dei ruoli
