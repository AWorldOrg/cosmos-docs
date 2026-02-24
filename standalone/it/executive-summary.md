# Piattaforma AWorld

**Executive Summary - Architettura, sicurezza e affidabilità**

## 1. Prodotto e architettura

### 1.1 Infrastruttura cloud

L'intera infrastruttura di AWorld è cloud-native e ospitata su Amazon Web Services (AWS). La scelta di un approccio completamente serverless permette di eliminare la gestione manuale dei server fisici o delle macchine virtuali, allocando le risorse computazionali dinamicamente in base alla domanda.

Le componenti chiave dell'infrastruttura includono:

**Computing**: utilizzo di AWS Lambda e API Gateway per una gestione efficiente delle richieste e una scalabilità automatica che si adatta ai picchi di traffico senza interruzioni di servizio.

**Database**: adozione di Amazon DynamoDB per gestire i volumi di dati con bassa latenza e garantire una rigorosa segregazione dei dati. Nello stack viene anche affiancato un database Cloudflare D1 dedicato per permettere indicizzazioni e assolvere ad alcune funzioni di applicazione.

**Performance**: implementazione di strategie di caching distribuito e bilanciamento del carico per ottimizzare i tempi di risposta e garantire la business continuity.

Il modello adottato garantisce alte prestazioni e resilienza intrinseca: l'infrastruttura è distribuita su più regioni AWS con strategie di Disaster Recovery attive per assicurare la continuità operativa anche in caso di guasti localizzati.

### 1.2 Architettura a livelli

Il sistema è organizzato in livelli logici distinti che separano le responsabilità, facilitando la manutenzione e l'evoluzione della piattaforma:

**Account & User Layer**: è responsabile della gestione sicura delle identità, dei permessi e dell'autenticazione (gestita via AWS Cognito e JWT). Supporta nativamente architetture multi-tenant.

**Gamification Layer**: il cuore dell'engagement engine. Gestisce le logiche di gioco come le classifiche, i livelli, badge e progressi, permettendo di trasformare le attività degli utenti in risultati misurabili.

**Catalog Layer**: gestisce la distribuzione dei contenuti formativi, permettendo all'azienda di utilizzare sia il catalogo validato di AWorld sia di caricare i propri contenuti proprietari.

Lato utente, l'ecosistema si compone di una Web App per le risorse (fruibile da mobile e desktop) e di un Backoffice per l'amministrazione, la gestione e assegnazione dei percorsi e l'analisi dei dati.

### 1.3 Multi-tenancy e scalabilità

Il sistema implementa un modello multi-tenant avanzato che garantisce l'isolamento completo dei dati tra diverse organizzazioni. Ogni richiesta API è automaticamente confinata al perimetro dei dati del cliente grazie a chiavi primarie composte su DynamoDB, impedendo fisicamente l'accesso trasversale ai dati di altri tenant.

L'architettura serverless permette una scalabilità automatica che si adatta dinamicamente ai volumi di traffico. Durante i picchi di utilizzo, il sistema attiva istanze aggiuntive in millisecondi senza necessità di provisioning manuale, garantendo prestazioni costanti anche in condizioni di carico elevato. Questa elasticità intrinseca elimina i costi fissi associati a infrastrutture tradizionali, ottimizzando la spesa in base all'utilizzo effettivo.

## 2. Sicurezza, compliance e gestione dati

### 2.1 Sicurezza e protezione

La sicurezza è integrata in ogni livello dell'architettura (Privacy by Design), con particolare attenzione alla protezione dei dati aziendali in contesti enterprise.

**Multi-tenancy e segregazione**: il sistema implementa un modello di isolamento logico rigoroso. Ogni richiesta API è automaticamente confinata al perimetro dei dati del cliente grazie a chiavi primarie composte su DynamoDB, impedendo fisicamente l'accesso trasversale ai dati.

**Crittografia**: tutti i dati sono cifrati sia in transito (TLS 1.2/1.3) che a riposo (AES-256), utilizzando algoritmi sicuri per prevenire accessi non autorizzati. La gestione delle chiavi di crittografia è centralizzata e automatizzata tramite AWS, riducendo i rischi di esposizione.

**Controllo accessi (RBAC/ABAC)**: la gestione dei permessi si basa su ruoli (Role-Based Access Control) con la possibilità di evolvere verso controlli basati su attributi (ABAC) per una granularità ancora maggiore. L'autenticazione delle API è gestita tramite AWS Lambda Authorizer, che valida ogni singola richiesta in tempo reale verificando l'autenticità del token e i permessi associati.

**Protezione attiva**: la piattaforma è protetta da Web Application Firewall (WAF) e sistemi di rilevamento minacce che monitorano il traffico per bloccare tentativi di abuso, attacchi DDoS o injection. Policy di rate limiting impediscono sovraccarichi e garantiscono una distribuzione equa delle risorse tra i diversi tenant.

### 2.2 Conformità GDPR e certificazioni

La piattaforma è progettata con approccio Privacy by Design per garantire la piena conformità al GDPR. Il sistema implementa principi di data minimization, raccogliendo esclusivamente i dati personali strettamente necessari al funzionamento del servizio, e applica tecniche di pseudonimizzazione per ridurre l'esposizione di informazioni sensibili.

Gli utenti hanno pieno controllo sui propri dati personali: la piattaforma supporta nativamente tutti i diritti degli interessati previsti dal GDPR, inclusi il diritto alla portabilità dei dati (export in formato strutturato), il diritto all'oblio (cancellazione completa) e il diritto di accesso (query completa dei dati personali).

Ogni operazione è tracciata tramite audit logging dettagliato, con timestamp standardizzati e log immutabili che garantiscono la trasparenza delle attività e supportano verifiche di conformità. Tutti i dati sono residenti al 100% in data center europei (regione primaria eu-west-1, Irlanda), assicurando il rispetto dei requisiti di data residency e sovranità dei dati.

L'organizzazione ha implementato un Sistema di Gestione della Sicurezza delle Informazioni (ISMS) conforme allo standard ISO 27001:2022, con controlli verificati tramite audit interni annuali. La certificazione formale è attualmente in fase di ottenimento.

### 2.3 Autenticazione e autorizzazione

La piattaforma adotta meccanismi di autenticazione moderni e sicuri. Per gli utenti finali, il sistema implementa autenticazione passwordless basata su One-Time Password via email (EMAIL_OTP), eliminando i rischi associati alla gestione di credenziali permanenti e semplificando l'esperienza utente.

Per le integrazioni machine-to-machine (M2M) con sistemi aziendali, la piattaforma supporta lo standard OAuth2 Client Credentials, permettendo ai backend dei clienti di interagire con le API in modo sicuro e automatizzato.

L'identity management è gestito tramite AWS Cognito, che fornisce token JWT (JSON Web Token) con claims workspace-scoped per garantire l'isolamento multi-tenant a livello di autorizzazione. Gli access token hanno una validità di 1 ora, mentre i refresh token rimangono validi per 30 giorni, bilanciando sicurezza e usabilità. Ogni richiesta API è validata in tempo reale da un Lambda Authorizer che verifica l'autenticità del token e i permessi associati.

## 3. Affidabilità e continuità operativa

### 3.1 Disaster Recovery e business continuity

Per garantire la continuità operativa anche in scenari critici, AWorld implementa un'architettura active-active distribuita su più regioni AWS. La configurazione primaria risiede in eu-west-1 (Irlanda), con replica automatica su eu-north-1 (Stoccolma) che mantiene sincronizzati dati e servizi in tempo reale.

In caso di guasto localizzato o indisponibilità di una regione, il sistema attiva automaticamente procedure di failover tramite AWS Route 53, deviando il traffico verso l'istanza funzionante senza interruzione percepibile per gli utenti finali. Questo approccio garantisce obiettivi di recupero rigorosi: Recovery Time Objective (RTO) inferiore o uguale a 24 ore e Recovery Point Objective (RPO) inferiore o uguale a 1 ora, assicurando che in caso di disaster la perdita di dati sia minima e il ripristino del servizio avvenga rapidamente.

Il sistema è dotato di monitoraggio proattivo continuo che analizza costantemente le metriche di utilizzo e rileva anomalie in tempo reale. In caso di degrado delle prestazioni o comportamenti sospetti, vengono attivate automaticamente contromisure per preservare la stabilità del servizio e prevenire interruzioni.

### 3.2 Performance e SLA

La piattaforma garantisce elevati standard di affidabilità con un uptime annuale superiore o uguale al 99,9%, monitorato continuamente tramite AWS CloudWatch Application Signals. Le performance delle API sono ottimizzate per rispondere rapidamente: almeno il 99% delle richieste viene completato in meno di 1000 millisecondi, con un response time al 95° percentile inferiore a 2 secondi anche sotto carico.

Il tasso di errore è mantenuto al di sotto dello 0,5%, garantendo stabilità e prevedibilità del servizio. In caso di anomalie, il sistema di supporto tecnico è strutturato per rispondere tempestivamente: gli incidenti critici (P1) vengono presi in carico entro 4 ore lavorative, mentre le richieste standard (P2) ricevono risposta entro 1 giorno lavorativo.

Il monitoraggio in tempo reale e l'analisi proattiva delle metriche permettono di identificare potenziali problemi prima che impattino gli utenti, assicurando un'esperienza d'uso fluida e affidabile per tutti i clienti enterprise.
