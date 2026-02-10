Questa guida spiega il concetto di workspace nella piattaforma AWorld e come gestirli in modo efficace.

## Cos'e' un Workspace?

Un workspace e' un ambiente isolato all'interno di un account che fornisce uno spazio dedicato per le diverse fasi del ciclo di vita della tua applicazione o per diversi team all'interno della tua organizzazione. Ogni account puo' avere piu' workspace, consentendo una gestione organizzata delle risorse e del controllo degli accessi.

## Gerarchia dei Workspace

Nella piattaforma AWorld, la gerarchia organizzativa e':

1. **Piattaforma**: La piattaforma AWorld di livello superiore
2. **Account**: Un tenant nell'architettura multi-tenant
3. **Workspace**: Un ambiente isolato all'interno di un account
4. **Risorse**: Servizi, configurazioni e dati all'interno di un workspace

## Tipologie Comuni di Workspace

Anche se puoi organizzare i workspace in base alle tue esigenze, le configurazioni piu' comuni includono:

- **Development**: Per lo sviluppo e il test di nuove funzionalita'
- **Staging**: Per i test pre-produzione e il controllo qualita'
- **Production**: Per le applicazioni live che servono gli utenti finali

In alternativa, potresti creare workspace per diversi:

- Team all'interno della tua organizzazione
- Progetti cliente o unita' di business
- Tipologie di applicazioni o servizi

## Risorse del Workspace

Ogni workspace opera come un ambiente isolato con le proprie:

- **Utenti**: Utenti a livello di workspace con ruoli e permessi specifici
- **Configurazione**: Impostazioni specifiche del workspace
- **Risorse**: API key, servizi e dati
- **Log e Metriche**: Dati operativi specifici del workspace

## Permessi del Workspace

L'accesso ai workspace e' controllato tramite un sistema di permessi:

- **Utenti a livello di principal** possono accedere e gestire piu' account e workspace
- **Amministratori del workspace** possono gestire un workspace specifico e i suoi utenti
- **Utenti del workspace** hanno accesso alle risorse all'interno del workspace assegnato, in base ai loro ruoli

## Best Practice

### Convenzioni di Denominazione dei Workspace

Stabilisci una convenzione di denominazione coerente per i workspace in modo da renderli facilmente identificabili:

- Includi lo scopo (ad esempio, "dev", "staging", "prod")
- Considera l'inclusione di identificatori di team o progetto
- Usa pattern coerenti (ad esempio, "progetto-ambiente")

### Isolamento delle Risorse

- Mantieni i workspace di sviluppo e produzione completamente separati
- Evita di condividere credenziali sensibili tra i workspace
- Implementa policy di sicurezza diverse in base allo scopo del workspace

### Gestione degli Accessi Utente

- Effettua regolarmente un audit degli accessi utente ai workspace
- Limita l'accesso al workspace di produzione al personale essenziale
- Crea workspace temporanei per collaboratori esterni o progetti temporanei

### Ciclo di Vita del Workspace

- Elimina o archivia i workspace non utilizzati
- Documenta lo scopo e la proprieta' di ogni workspace

## Dati del Workspace

I dati all'interno di un workspace sono logicamente isolati dagli altri workspace per impostazione predefinita. Questo offre diversi vantaggi:

- **Sicurezza**: Le violazioni dei dati in un workspace non influenzano gli altri
- **Organizzazione**: Organizzazione piu' chiara dei dati per ambiente o scopo
- **Testing**: Possibilita' di testare con dati realistici senza influenzare la produzione
- **Conformita'**: Piu' facile implementare requisiti di residenza dei dati o di conformita'

## Esempio di Configurazione del Workspace

Un'organizzazione tipica potrebbe utilizzare la seguente configurazione dei workspace:

- **Workspace di Development**: Per gli ingegneri, per sviluppare e testare funzionalita'
- **Workspace di QA**: Per i test di controllo qualita'
- **Workspace di Staging**: Per la verifica finale pre-produzione
- **Workspace di Production**: Per l'ambiente live utilizzato dai clienti
