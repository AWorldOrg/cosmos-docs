# Comprendere il Multi-tenancy

Questa guida spiega l'architettura multi-tenant della piattaforma Cosmos e come questa consente l'isolamento sicuro delle risorse e l'erogazione scalabile dei servizi.

## Cos'è il Multi-tenancy?

Il multi-tenancy è un'architettura software in cui una singola istanza di software serve più clienti o "tenant". I dati e la configurazione di ciascun tenant rimangono isolati dagli altri tenant, anche se condividono l'infrastruttura sottostante e il codice dell'applicazione.

Nella piattaforma Cosmos, un **Account** rappresenta un tenant – tipicamente un'organizzazione o un'azienda che utilizza la piattaforma.

## Architettura Multi-tenant in Cosmos

La piattaforma Cosmos implementa un'architettura multi-tenant gerarchica:

```
Piattaforma
└── Account (Tenant)
    └── Workspace
        └── User
```

### Componenti Chiave

- **Piattaforma**: Il sistema Cosmos di livello superiore che ospita tutti gli account
- **Account**: Un tenant con i propri dati e configurazione isolati
- **Workspace**: Un ambiente all'interno di un account (es. sviluppo, staging, produzione)
- **User**: Un utente a livello di workspace con permessi specifici
- **Principal**: Un utente a livello di piattaforma che può operare attraverso gli account

## Isolamento dei Tenant

La piattaforma Cosmos garantisce l'isolamento dei tenant a più livelli:

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

### Accesso API

Tutte le chiamate API sono autenticate e limitate al contesto del tenant appropriato:

- Le API del contesto App operano all'interno di uno specifico workspace, offrendo funzionalità rivolte all'utente
- Le API del contesto Dashboard operano all'interno di uno specifico workspace, offrendo funzionalità di gestione e osservabilità
- Le API del contesto Portal possono operare attraverso account e workspace (solo per i principal)

## Vantaggi del Multi-tenancy

L'architettura multi-tenant di Cosmos offre diversi vantaggi:

### Per i Fornitori di Servizi

- **Efficienza Operativa**: Gestire una singola istanza software è più efficiente che gestire istanze separate per ogni cliente
- **Ottimizzazione delle Risorse**: L'infrastruttura condivisa porta a un migliore utilizzo delle risorse
- **Manutenzione Semplificata**: Gli aggiornamenti e i miglioramenti beneficiano simultaneamente tutti i tenant
- **Efficacia dei Costi**: Costi operativi inferiori rispetto ai deployment single-tenant

### Per i Tenant (Account)

- **Onboarding Rapido**: Configurazione rapida senza complesse procedure di provisioning dell'infrastruttura
- **Aggiornamenti Automatici**: Accesso sempre alle funzionalità e patch di sicurezza più recenti
- **Scalabilità**: L'infrastruttura si ridimensiona con le esigenze di utilizzo
- **Flessibilità dei Workspace**: Possibilità di creare più ambienti isolati all'interno di un account

## Considerazioni sulla Sicurezza

Sebbene il multi-tenancy offra molti vantaggi, richiede anche un'attenta implementazione della sicurezza:

- **Autenticazione**: Robusta verifica dell'identità per garantire che gli utenti accedano solo ai loro account autorizzati
- **Autorizzazione**: Controlli di permesso granulari per limitare l'accesso all'interno degli account
- **Isolamento dei Dati**: Forti confini tra i dati dei tenant
- **Logging e Auditing**: Monitoraggio completo delle attività per rilevare tentativi di accesso non autorizzati

## Utilizzo API Multi-tenant

Quando si interagisce con le API Cosmos, il contesto del tenant è stabilito attraverso l'autenticazione:

1. **Autenticazione Utente**: Al login, l'utente è associato a uno specifico workspace e account
2. **Token di Accesso**: Il token JWT contiene claims sull'identità dell'utente e sugli ambiti tenant consentiti
3. **Richieste API**: Tutte le chiamate API includono il token di accesso, che determina il contesto del tenant

## Best Practices per l'Operazione Multi-tenant

### Per gli Amministratori di Piattaforma

- Controllare regolarmente i meccanismi di isolamento dei tenant
- Monitorare le potenziali vulnerabilità di accesso cross-tenant
- Implementare limiti di frequenza per prevenire la monopolizzazione delle risorse da parte dei tenant
- Garantire procedure adeguate di backup e disaster recovery per tutti i tenant

### Per gli Amministratori di Account

- Implementare una chiara strategia di workspace per i diversi ambienti
- Rivedere regolarmente i permessi di accesso degli utenti
- Utilizzare workspace separati per sviluppo e produzione
- Seguire il principio del privilegio minimo nell'assegnazione dei ruoli

## Argomenti Correlati

- [Lavorare con i Workspace](./workspace.md)
- [Autenticazione & Autorizzazione](./autenticazione.md)
