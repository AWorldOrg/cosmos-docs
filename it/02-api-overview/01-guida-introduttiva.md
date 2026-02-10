## Panoramica

AWorld è una piattaforma SaaS multi-tenant che fornisce una suite di API in tre contesti: App, Dashboard e Portal. Questa guida ti accompagnerà nella configurazione iniziale e nei passaggi di base per l'integrazione.

## Prerequisiti

Prima di iniziare, avrai bisogno di:

- Un account AWorld (fornito dal tuo amministratore o creato tramite registrazione)
- Conoscenza di base di REST o GraphQL (per le interazioni con le API)
- Un ambiente di sviluppo con il linguaggio/framework che preferisci

## Configurazione dell'Account e del Workspace

1. **Accesso all'Account**: Riceverai un'email di invito con le istruzioni per accedere al tuo account AWorld.

2. **Tipi di Utente**:
   - Se sei un **Principal** (utente a livello di piattaforma), avrai accesso alla gestione di più account.
   - Se sei un **User** (utente a livello di workspace), avrai accesso a un workspace specifico all'interno di un account.

3. **Selezione del Workspace**: Una volta effettuato l'accesso, potrai selezionare il tuo workspace se hai accesso a più workspace.

## Autenticazione

AWorld utilizza AWS Cognito con un dominio personalizzato per l'autenticazione. Per una guida completa, consulta [Autenticazione](apidog://link/pages/1215379).

### Panoramica Rapida sull'Autenticazione

1. **Registrazione e Accesso**:
   - Utilizza il flusso di autenticazione standard OAuth2
   - A seguito di un'autenticazione riuscita, riceverai i token di accesso e di aggiornamento

2. **Utilizzo dei Token**:
   - Includi il token di accesso in tutte le richieste API come Bearer token:

   ```
   Authorization: Bearer IL_TUO_TOKEN_DI_ACCESSO
   ```

   - Implementa la logica di aggiornamento del token per ottenere nuovi token di accesso quando scadono

## Fondamenti delle API

AWorld fornisce tre contesti API:

- **Consumer / Contesto App**: Per le funzionalità rivolte all'utente all'interno di un workspace
- **Admin / Contesto Dashboard**: Per le funzionalità di gestione e osservabilità all'interno di un workspace
- **Contesto Portal**: Per le operazioni a livello di piattaforma tra account e workspace (solo per i principal)

### Effettuare la Prima Chiamata API

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
   - [API Consumer/App](apidog://link/folders/4112890)
   - Riferimento API Dashboard
   - Riferimento API Portal

2. **Approfondisci i Concetti Chiave**:
   - [Multi-tenancy](apidog://link/pages/1215383)
   - [Workspace](apidog://link/pages/1215382)

3. **Best Practice per l'Integrazione**:
   - Implementa una corretta gestione degli errori per le chiamate API
   - Configura la logica di aggiornamento dei token per gestire i token di accesso in scadenza
   - Utilizza la paginazione per gestire grandi quantità di dati
   - Richiedi solo i campi necessari nelle query GraphQL

## Problemi Comuni e Risoluzione dei Problemi

### Problemi di Autenticazione

- **Token Non Validi**: Assicurati di utilizzare un token di accesso valido e non scaduto
- **Permesso Negato**: Verifica che il tuo utente abbia i permessi necessari per l'operazione richiesta
- **Contesto Errato**: Conferma di stare utilizzando il contesto API corretto per la tua operazione

### Utilizzo delle API

- **Sintassi GraphQL**: Valida la sintassi GraphQL prima di inviare le richieste
- **Campi Obbligatori**: Assicurati che tutti i campi obbligatori siano inclusi nei parametri di input
- **Limiti di Frequenza**: Sebbene non ci siano limiti di frequenza in pre-alpha, presta attenzione alle chiamate API eccessive

## Supporto e Risorse

- **Documentazione**: Consulta questo sito di documentazione per informazioni dettagliate
- **Supporto**: Contatta l'amministratore del tuo account per assistenza specifica sulla piattaforma
- **Risorse GraphQL**: Visita [graphql.org](https://graphql.org/learn/) per risorse di apprendimento su GraphQL
