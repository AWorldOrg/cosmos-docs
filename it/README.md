# Documentazione AWorld

Benvenuti alla documentazione ufficiale della piattaforma SaaS AWorld.

## Contenuti

- [Introduzione](#introduzione)
- [Riferimento API](#riferimento-api)
- [Guide](#guide)
- [Autenticazione](#autenticazione)
- [Concetti Chiave](#concetti-chiave)

## Introduzione

AWorld è una piattaforma SaaS multi-tenant che offre una suite di API in tre contesti distinti: App, Dashboard e Portal. La piattaforma è progettata con un approccio incentrato sull'utente, supportando anche interazioni machine-to-machine (M2M) attraverso client credentials.

> **Importante**: Le API AWorld sono attualmente in **fase pre-alpha** e sono in fase di intenso sviluppo. Nuovi aggiornamenti vengono rilasciati quotidianamente, il che potrebbe introdurre modifiche alle API. Si prega di consultare regolarmente la documentazione per le informazioni più recenti.

## Riferimento API

Documentazione dettagliata per tutte le API disponibili:

- [Riferimento API Contesto App](./riferimento-api/app/README.md) - API per il contesto App
- [Riferimento API Contesto Dashboard](./riferimento-api/dashboard/README.md) - API per il contesto Dashboard
- [Riferimento API Contesto Portal](./riferimento-api/portal/README.md) - API per il contesto Portal

## Guide

Guide passo-passo per attività comuni:

- [Primi Passi](./guide/primi-passi.md)
- [Autenticazione & Autorizzazione](./guide/autenticazione.md)
- [Lavorare con i Workspace](./guide/workspace.md)
- [Comprendere il Multi-tenancy](./guide/multi-tenancy.md)

## Autenticazione

AWorld utilizza AWS Cognito con un dominio personalizzato per l'autenticazione, implementando i flussi standard OAuth2. Per istruzioni dettagliate sull'autenticazione, consulta la nostra [Guida all'Autenticazione](./guide/autenticazione.md).

## Concetti Chiave

### Account

Un Account rappresenta un tenant nell'architettura multi-tenant di AWorld. Ogni organizzazione ha tipicamente il proprio Account, che funge da contenitore di primo livello per tutte le risorse relative a quell'organizzazione.

### Workspace

Ogni Account può avere più Workspace, che sono ambienti isolati all'interno di un Account. Le configurazioni comuni dei workspace includono:
- Sviluppo
- Staging
- Produzione

I Workspace consentono la separazione delle risorse e dei controlli di accesso all'interno dello stesso Account.

### Principal

Un Principal è un utente a livello di piattaforma che ha accesso attraverso gli Account e i Workspace. Mentre i Principal possono gestire più account, più comunemente gestiscono più Workspace all'interno di un singolo Account. I Principal in genere rappresentano amministratori o super-utenti con permessi elevati.

### User

Un User è limitato a uno specifico workspace all'interno di un account. Gli utenti hanno permessi limitati al loro workspace assegnato e in genere rappresentano utenti regolari della piattaforma.

## Tipi di API

AWorld fornisce sia API GraphQL che REST:

- **API GraphQL**: Tipo di API attualmente disponibile, che offre query e mutation flessibili
- **API REST**: Avranno parità di funzionalità con le API GraphQL ma non sono ancora pubblicate
