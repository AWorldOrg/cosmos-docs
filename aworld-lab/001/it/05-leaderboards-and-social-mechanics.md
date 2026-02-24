Questa sezione tratta le **meccaniche sociali e competitive** di AWorld Lab — le funzionalità che aggiungono una dimensione di community all'esperienza di engagement. Le leaderboard trasformano l'accumulo di punti in un'esperienza competitiva dinamica, i gruppi abilitano il targeting basato su team e il logging completo fornisce visibilità misurabile sui progressi. Per le meccaniche individuali di tracciamento degli obiettivi, incluse missioni e streak, si veda la documentazione su missioni e progressione. Per le attività e i contenuti fondamentali, si rimanda alla documentazione sulle attività.

## Leaderboard

Il sistema di leaderboard di AWorld Lab trasforma l'accumulo di valuta virtuale in un'**esperienza competitiva dinamica**, consentendo agli utenti di confrontare i punteggi in tempo reale. Il sistema è costruito su un'**architettura a due livelli** che separa ciò che viene classificato da quando e come viene visualizzato.

### Architettura a due livelli: configurazione e Runtime

Il sistema di leaderboard è composto da due componenti distinti:

- **Leaderboard Configuration**: un template che definisce **cosa** viene classificato — quali utenti sono inclusi, quali metriche vengono aggregate e come vengono calcolati i punteggi.
- **Runtime Leaderboard**: un'istanza che definisce **quando** la classifica si applica — l'intervallo temporale, la ricorrenza e lo stato corrente.

Questa separazione consente a una singola configurazione di alimentare più istanze runtime. Ad esempio, una configurazione "Top Punti Questa Settimana" può generare automaticamente una nuova istanza settimanale ogni lunedì, ciascuna con classifiche indipendenti.

### Leaderboard Configuration

Ogni configurazione definisce una **specifica di query** che determina come vengono calcolate le classifiche:

- **Selezione utenti**: quali utenti sono idonei per la leaderboard, filtrati per qualsiasi attributo utente o tag.
- **Aggregazione metriche**: quali dati aggregare — tipicamente transazioni in valuta virtuale, ma configurabile per includere altre metriche.
- **Calcolo del punteggio**: come viene calcolato il punteggio finale a partire dai dati aggregati.
- **Classificazione**: l'ordine in cui gli utenti vengono classificati (tipicamente per punteggio, in ordine decrescente).

Impostazioni aggiuntive di visualizzazione includono:

- **Top N**: il numero di utenti da visualizzare (configurabile da 1 a 100).
- **Mostra posizione**: se visualizzare la posizione numerica dell'utente.
- **Mostra punteggio**: se visualizzare il valore del punteggio calcolato.

### Istanze Runtime: intervalli temporali e ricorrenza

Ogni istanza runtime della leaderboard opera all'interno di un intervallo temporale definito:

- **Permanente**: la leaderboard è attiva a tempo indeterminato con una classifica cumulativa.
- **Intervallo**: la leaderboard è attiva all'interno di una data di inizio e fine specifiche — ideale per campagne o eventi.
- **Ricorrente**: la leaderboard si resetta automaticamente a intervalli regolari.

Le leaderboard ricorrenti supportano diversi **pattern di ricorrenza**:

- **Giornaliera**: le classifiche si resettano ogni giorno.
- **Settimanale**: le classifiche si resettano ogni settimana.
- **Mensile**: le classifiche si resettano ogni mese.
- **Personalizzata**: ricorrenza definita da una pianificazione personalizzata.

Ogni istanza segue un **ciclo di vita basato su stati**: **Pending** (prima dell'avvio), **Active** (accetta e calcola le classifiche) e **Ended** (classifiche finali congelate).

### Modello di calcolo

I punteggi delle leaderboard vengono **calcolati al momento della query** utilizzando query di aggregazione sul data store analitico della piattaforma. Questo approccio garantisce che:

- Le classifiche riflettano sempre i **dati più aggiornati** senza ritardi di sincronizzazione.
- Le configurazioni possano definire **formule di punteggio arbitrarie** — non semplici somme, ma calcoli ponderati, aggregazioni filtrate ed espressioni personalizzate.
- Il sistema possa essere supportato da diversi motori di calcolo a seconda dei requisiti di deployment, da data store analitici basati su SQL per la flessibilità a database in-memory per scenari ad alta frequenza di aggiornamento.

### Segmentazione e visualizzazione

Anziché offrire tipologie di leaderboard predefinite, il modello di configurazione di AWorld Lab consente **qualsiasi segmentazione** attraverso le definizioni di query:

- **Leaderboard globali**: includono tutti gli utenti del workspace, incoraggiando una competizione ampia.
- **Leaderboard di community**: filtrano gli utenti per tag di gruppo, favorendo la competizione tra pari — come dipartimenti, team o aree geografiche.
- **Leaderboard di missione**: limitano le classifiche agli utenti che partecipano a una specifica missione, con un intervallo temporale corrispondente alla durata della missione.
- **Segmenti personalizzati**: qualsiasi combinazione di attributi utente e tag può definire il pubblico di una leaderboard.

Questa flessibilità consente ai clienti di creare esperienze competitive mirate per ogni contesto, dalle sfide aziendali su larga scala alle competizioni di team più ristrette.

## Gruppi e cluster di utenti

AWorld Lab fornisce un **sistema di raggruppamento basato su tag** che consente ai clienti di organizzare gli utenti in cluster distinti in base ad attributi, ruoli o criteri organizzativi.

### Raggruppamento basato su Tag

I tag possono rappresentare qualsiasi classificazione significativa: dipartimenti, team di progetto, livelli utente, aree geografiche o livelli di partecipazione. Il sistema supporta l'**assegnazione di più tag a ciascun utente**, abilitando strutture di gruppo flessibili e sovrapponibili. Per informazioni dettagliate sul modello dei tag, si veda la sezione tag e targeting delle entità nella documentazione sulle missioni.

### Meccaniche mirate ai gruppi

Questo meccanismo di raggruppamento si integra direttamente con le funzionalità competitive della piattaforma:

- **Missioni di gruppo**: missioni assegnate agli utenti che corrispondono a specifiche combinazioni di tag, abilitando percorsi di engagement differenziati per diversi segmenti.
- **Leaderboard di community**: leaderboard limitate agli utenti all'interno di un gruppo specifico, favorendo la competizione tra pari anziché sull'intera base utenti.
- **Tracciamento del progresso collettivo**: i clienti possono misurare l'impatto aggregato e la partecipazione dei cluster di utenti taggati, fornendo visibilità sulle performance del team.

Il sistema di raggruppamento si adatta a vari modelli organizzativi — dalle **iniziative aziendali interne** segmentate per team o dipartimento, ai **programmi pubblici** rivolti a specifiche categorie di utenti. Ogni cliente mantiene il pieno controllo su come vengono definiti i gruppi e su come interagiscono con il più ampio sistema di *gamification*.

## Tracciamento del progresso e misurazione dell'impatto

Una caratteristica distintiva dell'infrastruttura di *gamification* di AWorld Lab è la capacità di **monitorare in dettaglio il progresso degli utenti** e misurare l'impatto delle azioni completate.

### Logging completo

La piattaforma mantiene un **audit trail completo** su ogni dominio di *gamification*:

- **Activity Log**: ogni azione eseguita, con esiti, valori e timestamp.
- **Mission Log**: aggiornamenti di progresso ed eventi di completamento per ogni missione.
- **Learning Path Log**: stati di avvio, progresso e completamento per ogni esperienza di apprendimento.
- **Learning Group Log**: progresso per sezione all'interno dei Learning Path.
- **Quiz Log**: ogni tentativo di quiz con risposte, esiti e difficoltà.
- **Slide Log**: tracciamento della visualizzazione e del completamento dei contenuti.
- **Streak Log**: cambiamenti di stato della streak e storico dei contributi.

Questa architettura di logging garantisce che ogni interazione dell'utente venga catturata e resa disponibile per l'analisi.

### Insight di engagement basati sui dati

Il sistema di logging completo fornisce ai clienti i dati necessari per:

- **Misurare il progresso individuale**: tracciare il percorso di ciascun utente attraverso attività, missioni ed esperienze di apprendimento.
- **Analizzare l'impatto collettivo**: aggregare le metriche di partecipazione tra gruppi, dipartimenti o l'intera base utenti.
- **Ottimizzare le strategie di engagement**: identificare quali missioni, contenuti e strutture di ricompense generano la partecipazione più elevata.
- **Reportistica sugli esiti**: generare report basati sull'evidenza riguardo l'impatto dei programmi di *gamification*.

Attraverso questo livello, la piattaforma non solo aumenta l'**engagement degli utenti** ma fornisce anche **metriche dettagliate sull'impatto delle azioni degli utenti**, trasformando la *gamification* in una potente leva di crescita misurabile per aziende e organizzazioni.
