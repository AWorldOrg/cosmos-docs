# Lavorare con i Workspace

Questa guida spiega il concetto di workspace nella piattaforma Cosmos e come gestirli efficacemente.

## Cos'è un Workspace?

Un workspace è un ambiente isolato all'interno di un account che fornisce uno spazio dedicato per diverse fasi del ciclo di vita dell'applicazione o per diversi team all'interno dell'organizzazione. Ogni account può avere più workspace, consentendo una gestione organizzata delle risorse e il controllo degli accessi.

## Gerarchia dei Workspace

Nella piattaforma Cosmos, la gerarchia organizzativa è:

1. **Piattaforma**: La piattaforma Cosmos di livello superiore
2. **Account**: Un tenant nell'architettura multi-tenant
3. **Workspace**: Un ambiente isolato all'interno di un account
4. **Risorse**: Servizi, configurazioni e dati all'interno di un workspace

## Tipi Comuni di Workspace

Mentre puoi organizzare i workspace in base alle tue esigenze, le configurazioni comuni includono:

- **Sviluppo**: Per costruire e testare nuove funzionalità
- **Staging**: Per test pre-produzione e controllo qualità
- **Produzione**: Per applicazioni live utilizzate dagli utenti finali

In alternativa, potresti creare workspace per diversi:

- Team all'interno della tua organizzazione
- Progetti client o unità di business
- Tipi di applicazioni o servizi

## Risorse del Workspace

Ogni workspace opera come un ambiente isolato con:

- **Utenti**: Utenti a livello di workspace con ruoli e permessi specifici
- **Configurazione**: Impostazioni specifiche per il workspace
- **Risorse**: Chiavi API, servizi e dati
- **Log e Metriche**: Dati operativi specifici per il workspace

## Permessi del Workspace

L'accesso ai workspace è controllato attraverso un sistema di permessi:

- **Utenti a livello di Principal** possono accedere e gestire più account e workspace
- **Amministratori del workspace** possono gestire uno specifico workspace e i suoi utenti
- **Utenti del workspace** hanno accesso alle risorse all'interno del loro workspace assegnato, in base ai loro ruoli

## Best Practices

### Convenzioni di Denominazione dei Workspace

Stabilisci una convenzione di denominazione coerente per i workspace per renderli facilmente identificabili:

- Includi lo scopo (es. "dev", "staging", "prod")
- Considera l'inclusione di identificatori di team o progetto
- Usa pattern coerenti (es. "progetto-ambiente")

### Isolamento delle Risorse

- Mantieni completamente separati i workspace di sviluppo e produzione
- Evita di condividere credenziali sensibili tra workspace
- Implementa diverse politiche di sicurezza in base allo scopo del workspace

### Gestione degli Accessi Utente

- Controlla regolarmente l'accesso degli utenti ai workspace
- Limita l'accesso al workspace di produzione al personale essenziale
- Crea workspace temporanei per collaboratori esterni o progetti temporanei

### Ciclo di Vita del Workspace

- Pulisci o archivia i workspace inutilizzati
- Documenta lo scopo e la proprietà di ciascun workspace

## Dati del Workspace

I dati all'interno di un workspace sono logicamente isolati dagli altri workspace per impostazione predefinita. Questo fornisce diversi vantaggi:

- **Sicurezza**: Le violazioni dei dati in un workspace non influenzano gli altri
- **Organizzazione**: Organizzazione più chiara dei dati per ambiente o scopo
- **Test**: Capacità di testare con dati realistici senza influenzare la produzione
- **Conformità**: Più facile implementare requisiti di residenza dei dati o conformità

## Esempio di Configurazione dei Workspace

Un'organizzazione tipica potrebbe utilizzare la seguente configurazione di workspace:

- **Workspace di Sviluppo**: Per gli ingegneri per costruire e testare funzionalità
- **Workspace QA**: Per test di controllo qualità
- **Workspace di Staging**: Per la verifica finale pre-produzione
- **Workspace di Produzione**: Per l'ambiente live utilizzato dai clienti

## Argomenti Correlati

- [Comprendere il Multi-tenancy](./multi-tenancy.md)
- [Autenticazione & Autorizzazione](./autenticazione.md)
