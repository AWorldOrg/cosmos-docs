# Primi Passi con AWorld

Questa guida ti aiuterà a configurare e iniziare a utilizzare rapidamente la piattaforma SaaS AWorld.

## Panoramica

AWorld è una piattaforma SaaS multi-tenant che fornisce una suite di API attraverso tre contesti: App, Dashboard e Portal. Questa guida ti accompagnerà attraverso la configurazione iniziale e i passaggi di base per l'integrazione.

## Prerequisiti

Prima di iniziare, avrai bisogno di:

- Un account AWorld (fornito dal tuo amministratore o creato tramite registrazione)
- Conoscenza base di GraphQL (per le interazioni con le API)
- Ambiente di sviluppo con il tuo linguaggio/framework preferito

## Configurazione di Account e Workspace

1. **Accesso all'Account**: Riceverai un'email di invito con le istruzioni per accedere al tuo account AWorld.

2. **Tipi di Utente**:
   - Se sei un **Principal** (utente a livello di piattaforma), avrai accesso per gestire più account.
   - Se sei un **User** (utente a livello di workspace), avrai accesso a uno specifico workspace all'interno di un account.

3. **Selezione del Workspace**: Una volta effettuato l'accesso, potrai selezionare il tuo workspace se hai accesso a più workspace.

## Autenticazione

AWorld utilizza AWS Cognito con un dominio personalizzato per l'autenticazione. Per una guida completa, consulta [Autenticazione & Autorizzazione](./autenticazione.md).

### Panoramica Rapida dell'Autenticazione

1. **Registrazione e Accesso**:
   - Utilizza il flusso di autenticazione standard OAuth2
   - Dopo un'autenticazione riuscita, riceverai token di accesso e refresh

2. **Utilizzo dei Token**:
   - Includi il token di accesso in tutte le richieste API come Bearer token:
   
   ```
   Authorization: Bearer YOUR_ACCESS_TOKEN
   ```

   - Implementa la logica di refresh token per ottenere nuovi token di accesso quando scadono

## Basi delle API

AWorld fornisce tre contesti API:

- **Contesto App**: Per funzionalità rivolte all'utente all'interno di un workspace
- **Contesto Dashboard**: Per funzionalità di gestione e osservabilità all'interno di un workspace
- **Contesto Portal**: Per operazioni a livello di piattaforma attraverso account e workspace (solo per i principal)

### La Tua Prima Chiamata API

Ecco un semplice esempio di invio di una risposta a un quiz utilizzando l'API del contesto App:

```javascript
async function submitQuizAnswer(quizId, answer, accessToken) {
  const mutation = `
    mutation SubmitQuiz($input: SubmitQuizInput!) {
      submitQuiz(input: $input) {
        quizId
        userId
        outcome
      }
    }
  `;

  const variables = {
    input: {
      quizId: quizId,
      answer: answer,
      context: "default"
    }
  };

  try {
    const response = await fetch('https://api.aworld.cloud/app/graphql', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': `Bearer ${accessToken}`
      },
      body: JSON.stringify({
        query: mutation,
        variables: variables
      })
    });

    const result = await response.json();
    
    if (result.errors) {
      console.error('Errori GraphQL:', result.errors);
      throw new Error(result.errors[0].message);
    }
    
    return result.data.submitQuiz;
  } catch (error) {
    console.error('Errore nell\'invio del quiz:', error);
    throw error;
  }
}
```

## Prossimi Passi

Dopo aver completato la configurazione iniziale, ecco alcuni passi successivi consigliati:

1. **Esplora i Riferimenti API**:
   - [Riferimento API Contesto App](../riferimento-api/app/README.md)
   - [Riferimento API Contesto Dashboard](../riferimento-api/dashboard/README.md)
   - [Riferimento API Contesto Portal](../riferimento-api/portal/README.md)

2. **Approfondisci i Concetti Chiave**:
   - [Lavorare con i Workspace](./workspace.md)
   - [Comprendere il Multi-tenancy](./multi-tenancy.md)

3. **Best Practices di Integrazione**:
   - Implementa una corretta gestione degli errori per le chiamate API
   - Configura la logica di refresh dei token per gestire i token di accesso in scadenza
   - Utilizza la paginazione per gestire grandi set di dati
   - Richiedi solo i campi necessari nelle query GraphQL

## Problemi Comuni e Risoluzione

### Problemi di Autenticazione

- **Token Non Validi**: Assicurati di utilizzare un token di accesso valido e non scaduto
- **Permesso Negato**: Verifica che il tuo utente disponga dei permessi necessari per l'operazione richiesta
- **Contesto Errato**: Conferma che stai utilizzando il contesto API corretto per la tua operazione

### Utilizzo API

- **Sintassi GraphQL**: Valida la tua sintassi GraphQL prima di inviare le richieste
- **Campi Obbligatori**: Assicurati che tutti i campi richiesti siano inclusi nei tuoi parametri di input
- **Limiti di Frequenza**: Sebbene non ci siano limiti di frequenza in fase pre-alpha, fai attenzione alle chiamate API eccessive

## Supporto e Risorse

- **Documentazione**: Consulta questo sito di documentazione per informazioni dettagliate
- **Supporto**: Contatta l'amministratore del tuo account per supporto specifico sulla piattaforma
- **Risorse GraphQL**: Visita [graphql.org](https://graphql.org/learn/) per risorse di apprendimento GraphQL
