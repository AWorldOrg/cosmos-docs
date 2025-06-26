# Quiz

> **Importante**: Questa documentazione dettagliata è fornita a scopo dimostrativo. Fai sempre riferimento allo schema GraphQL (utilizzando l'introspezione) per la documentazione API più aggiornata. Gli schemi evolvono nel tempo, e l'introspezione fornirà sempre la definizione corrente.

I quiz sono unità di valutazione interattive utilizzate in tutta la piattaforma AWorld per coinvolgere gli utenti e valutare le conoscenze. Questo documento fornisce informazioni complete sull'entità Quiz, le sue proprietà e come viene utilizzata in diversi contesti.

## Panoramica

I quiz nella piattaforma AWorld servono come strumenti di valutazione delle conoscenze che possono essere incorporati in vari tipi di contenuti. Supportano più livelli di difficoltà, internazionalizzazione attraverso traduzioni e tracciamento dettagliato dei risultati.

## Modello di Dati

### Campi Principali

| Campo             | Tipo              | Descrizione                                                   | Obbligatorio |
| ----------------- | ----------------- | ------------------------------------------------------------- | ------------ |
| `quizId`          | ID                | Identificatore unico per il quiz                              | Sì           |
| `difficulty`      | QuizDifficulty    | Livello di difficoltà: EASY, MEDIUM o HARD                    | Sì           |
| `answer`          | QuizAnswer        | Opzione di risposta corretta: opt1, opt2, opt3 o opt4         | Sì           |
| `syncWithCatalog` | Boolean           | Se il quiz si sincronizza con il catalogo                     | No           |
| `origin`          | QuizOrigin        | Origine del quiz: CATALOG o CUSTOM                            | Sì           |
| `placement`       | QuizPlacement     | Dove appare il quiz: STANDALONE, STORY o NEWS                 | Sì           |
| `quizCatalogId`   | ID                | Riferimento al quiz del catalogo se applicabile               | Sì           |
| `translations`    | [QuizTranslation] | Lista di traduzioni per diverse lingue                        | Sì           |
| `createdAt`       | AWSDateTime       | Timestamp di quando il quiz è stato creato                    | Sì (auto)    |
| `updatedAt`       | AWSDateTime       | Timestamp di quando il quiz è stato aggiornato l'ultima volta | Sì (auto)    |

### QuizTranslation

| Campo         | Tipo        | Descrizione                                                         | Obbligatorio |
| ------------- | ----------- | ------------------------------------------------------------------- | ------------ |
| `quizId`      | ID          | Riferimento al quiz padre                                           | Sì           |
| `lang`        | String      | Codice lingua (es. "en", "it")                                      | Sì           |
| `opt1`        | String      | Prima opzione di risposta                                           | Sì           |
| `opt2`        | String      | Seconda opzione di risposta                                         | Sì           |
| `opt3`        | String      | Terza opzione di risposta                                           | No           |
| `opt4`        | String      | Quarta opzione di risposta                                          | No           |
| `question`    | String      | Il testo della domanda del quiz                                     | Sì           |
| `explanation` | String      | Spiegazione della risposta corretta                                 | No           |
| `createdAt`   | AWSDateTime | Timestamp di quando la traduzione è stata creata                    | Sì (auto)    |
| `updatedAt`   | AWSDateTime | Timestamp di quando la traduzione è stata aggiornata l'ultima volta | Sì (auto)    |

### Schema GraphQL

```graphql
enum QuizDifficulty {
  EASY
  MEDIUM
  HARD
}

enum QuizAnswer {
  opt1
  opt2
  opt3
  opt4
}

enum QuizOrigin {
  CATALOG
  CUSTOM
}

enum QuizPlacement {
  STANDALONE
  STORY
  NEWS
}

enum QuizOutcome {
  SUCCESS
  FAIL
}

type Quiz {
  quizId: ID!
  difficulty: QuizDifficulty!
  answer: QuizAnswer!
  syncWithCatalog: Boolean
  origin: QuizOrigin!
  placement: QuizPlacement!
  quizCatalogId: ID!
  translations: [QuizTranslation!]!
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type QuizConnection {
  items: [Quiz!]!
  nextToken: String
}

type QuizTranslation {
  quizId: ID!
  lang: String!
  opt1: String!
  opt2: String!
  opt3: String
  opt4: String
  question: String!
  explanation: String
  createdAt: AWSDateTime!
  updatedAt: AWSDateTime!
}

type QuizLog {
  quizId: ID!
  userId: ID!
  lang: String!
  difficulty: QuizDifficulty!
  answer: QuizAnswer!
  outcome: QuizOutcome!
  context: String!
  createdAt: AWSDateTime!
}
```

## Ciclo di Vita

### Creazione

I quiz possono essere creati in due modi:
1. **Creazione personalizzata** (origin: CUSTOM) - Creati direttamente attraverso l'API Dashboard
2. **Sincronizzazione dal catalogo** (origin: CATALOG) - Importati dal catalogo quiz con personalizzazione opzionale

Quando si crea un quiz, è necessario fornire almeno una traduzione. La lingua principale dovrebbe corrispondere alla lingua predefinita del workspace.

### Aggiornamenti

I quiz possono essere aggiornati attraverso l'API Dashboard. Gli aggiornamenti ai quiz includono:
- Modifica delle proprietà del quiz (difficoltà, posizionamento, ecc.)
- Aggiunta, aggiornamento o rimozione di traduzioni
- Modifica della risposta corretta

### Eliminazione

Mentre i quiz possono essere logicamente eliminati (nascosti agli utenti), vengono tipicamente conservati per scopi analitici e di tracciamento.

## Utilizzo nei Diversi Contesti

### Contesto App

Nel contesto App, i quiz sono principalmente utilizzati dagli utenti finali. Vedi [Riferimento API Contesto App](../app/README.md#mutation-disponibili) per i dettagli.

Operazioni chiave:
- **Invio risposte** (mutation `submitQuiz`)
- **Elenco quiz disponibili** (query `listQuizzes`)

### Contesto Dashboard

Nel contesto Dashboard, i quiz sono gestiti dagli amministratori. Vedi [Riferimento API Contesto Dashboard](../dashboard/README.md#query-comuni) per i dettagli.

Operazioni chiave:
- **Creazione quiz** (mutation `createQuiz`)
- **Aggiornamento quiz** (mutation `updateQuiz`)
- **Archiviazione quiz** (mutation `archiveQuiz`)
- **Elenco e filtro quiz** (query `quizzes`)

## Considerazioni Speciali

### Internazionalizzazione

- Ogni quiz deve avere almeno una traduzione
- La domanda del quiz e almeno due opzioni di risposta sono richieste per ogni traduzione
- La best practice è fornire traduzioni per tutte le lingue supportate nel tuo workspace
- La terminologia coerente dovrebbe essere mantenuta tra le traduzioni

### Difficoltà del Quiz

Il livello di difficoltà influisce su:
- Aspettative dell'esperienza utente
- Analisi e reporting
- Algoritmi di raccomandazione
- Ricompense

Scegli i livelli di difficoltà in modo coerente in base a:
- Complessità della domanda
- Numero di opzioni di risposta plausibili
- Conoscenza del dominio richiesta

### Posizionamento del Quiz

Il tipo di posizionamento determina dove e come appare il quiz:
- **STANDALONE**: Quiz indipendenti accessibili direttamente
- **STORY**: Quiz incorporati nei contenuti delle storie
- **NEWS**: Quiz associati ad articoli di notizie

Ogni tipo di posizionamento può avere diverse considerazioni UX e requisiti di integrazione.

## Modelli Comuni

### Flusso di Invio Quiz

Un tipico flusso di invio di quiz include:
1. Recupero dei dettagli del quiz
2. Visualizzazione della domanda e delle opzioni all'utente
3. Raccolta della risposta dell'utente
4. Invio della risposta dell'utente tramite API
5. Visualizzazione del risultato e della spiegazione
6. Registrazione delle analitiche

### Distribuzione Localizzata dei Quiz

Per fornire quiz nella lingua preferita dell'utente:
1. Recupera la preferenza linguistica dell'utente
2. Interroga i quiz con traduzione corrispondente
3. Ricadi sulla lingua predefinita del workspace se non c'è corrispondenza
4. Visualizza la domanda e le opzioni tradotte

## Errori da Evitare

### Errori Comuni

1. **Traduzioni mancanti**: Fornisci sempre traduzioni per tutte le lingue supportate
2. **Difficoltà incoerente**: Mantieni criteri coerenti per i livelli di difficoltà
3. **Domande ambigue**: Assicurati che le domande abbiano risposte chiare e non ambigue
4. **Opzioni di risposta insufficienti**: Fornisci opzioni sufficienti per una valutazione significativa
5. **Spiegazioni mancanti**: Includi sempre spiegazioni per una migliore esperienza utente

## Esempi

### Creazione di un Quiz

```graphql
mutation CreateQuiz($input: CreateQuizInput!) {
  createQuiz(input: $input) {
    quizId
    difficulty
    answer
    origin
    placement
    translations {
      lang
      question
      opt1
      opt2
      opt3
      opt4
      explanation
    }
  }
}
```

Variabili:
```json
{
  "input": {
    "difficulty": "MEDIUM",
    "answer": "opt2",
    "origin": "CUSTOM",
    "placement": "STORY",
    "translations": [
      {
        "lang": "en",
        "question": "What is the capital of Italy?",
        "opt1": "Milan",
        "opt2": "Rome",
        "opt3": "Florence",
        "opt4": "Venice",
        "explanation": "Rome is the capital city of Italy."
      },
      {
        "lang": "it",
        "question": "Qual è la capitale d'Italia?",
        "opt1": "Milano",
        "opt2": "Roma",
        "opt3": "Firenze",
        "opt4": "Venezia",
        "explanation": "Roma è la capitale d'Italia."
      }
    ]
  }
}
```

### Utilizzo del Contesto nell'Invio dei Quiz

Il parametro `context` nell'invio dei quiz serve a uno scopo importante:

```graphql
# Input per l'invio di una risposta a un quiz.
input SubmitQuizInput {
  # ID del quiz a cui si risponde.
  quizId: ID!
  # Risposta selezionata dall'utente.
  answer: QuizAnswer!
  # Contesto in cui il quiz è stato risposto. Gli utenti possono rispondere a un quiz solo una volta per contesto.
  # Utilizzando il contesto in modo creativo, è possibile costruire logiche complesse (ad esempio, utilizzando una data, un mese, un contesto personalizzato, ecc.)
  context: String
}
```

Gli utenti possono rispondere a un quiz solo una volta per ogni contesto unico. Questo offre flessibilità per implementare vari scenari di quiz:
- Uso di contesti basati sulla data (es. "2025-03-18") per consentire tentativi quotidiani
- Uso di contesti di posizione (es. "homepage", "story-123") per diversi posizionamenti
- Uso di contesti sequenziali (es. "livello-1", "livello-2") per il tracciamento della progressione
- Uso di contesti personalizzati per flussi di lavoro specializzati

### Invio di una Risposta a un Quiz

```javascript
async function submitQuizAnswer(quizId, userAnswer, context = "default") {
  const mutation = `
    mutation SubmitQuiz($input: SubmitQuizInput!) {
      submitQuiz(input: $input) {
        quizId
        userId
        lang
        difficulty
        answer
        outcome
        context
      }
    }
  `;

  const variables = {
    input: {
      quizId: quizId,
      answer: userAnswer,
      context: context  // Usa strategicamente per il controllo della ripetizione
    }
  };

  const response = await fetch('https://v1.gql.app.aworld.cloud/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + accessToken
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
}
```

## Entità Correlate

- **QuizLog** - Registrazioni dei tentativi di quiz da parte degli utenti
- **User** - L'entità che tenta i quiz
- **QuizCatalog** - Fonte di quiz standard che possono essere sincronizzati

## Risorse Aggiuntive

- [API Contesto App](../app/README.md)
- [API Contesto Dashboard](../dashboard/README.md)
- [Guida alle Best Practice dei Quiz](#) (in arrivo)
- [Guida alle Analitiche dei Quiz](#) (in arrivo)
