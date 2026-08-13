mercoledì 22 luglio 2026
------------------------
9:30-10:15 - riunione su metodo lavoro ecc...

10:15 - Marco su interviste

10:30 -> 12:30 Ragguaglio con Rumi (Libera e altri)

(tiziano) caricata matrice di fattibilità in previsione dell'incontro clienti

a fine giornata: creato DB Azure Flexible e caricati DB storico PM10


giovedi 23 luglio 2026
----------------------

**suddivisione lavoro:**
- (libera) indagine per punto 6 - file Json giornaliero dei dati delle centraline
- (vanessa) esplorazione PowerBI dashboard principale
- (tiziano) db esplorazione tabelle (rinomina colonne, realizzazione dimensione stazioni)

Venerdi 24-luglio-2026
----------------------
tiziano: proposta, lavoriamo in asincrono aggiungendo qui i punti che riteniamo (Libera!!! solo i punti a grandi linee per favore altrimenti io e forse anche Vanessa ci perdiamo)

TT punto 1: cercare informazioni sui meccanismi delle infrazioni europee
TT punto 2: analizzare i siti di citizen science per vedere se è possibile integrare i dati da quel che ho visto io non ci sono storici di dati, mah
TT punto 3: dovremmo fare il data catalog, per fortuna il set di dati sia delle due dimensioni sia degli storici delle misure sono abbastanza snelli

TT: proposta di costruire un reticolo triangolare (Triangulated Irregular Network) per definire le stime di 
    valori PM2.5 e PM10 in quanti più comuni possibili. Facendo riferimento al centroide del Comune espresso in longitudine e latitudine ed associando detti Comuni a triangoli del reticolo ai cui vertici stanno tre centraline, stazioni ARPAE [ci guardo io che sono curioso di questa tecnica]

Martedi` 28-luglio-2026
----------------------
Libera: codice python in locale per 
estrarre i dati degli ultimi 3 giorni
creata la tabella bollettino in postgres locale
TODO: generalizzare l'estrazione degli ultimi 3 giorni dai json

Vanessa: impostazione dashboard la mattina, sviluppo dashboard pomeriggio insieme a tutto il team

Rumi: ricerche in collaborazione con Vanessa per fare la dashboard

Libera + Tiziano: merge dev in main

Prospetto per la mattina di Mercoledì 29-luglio-2026:
1) fare -->    Libera, Rumi e Tiziano: revisione del pbix di presentazione dello stato dell'arte del progetto in vista dell'incontro con i clienti (16:00-16:30)
2) discutere --> prelievo parametri misure giornaliere

Mercoledì 29-luglio-2026
------------------------
meet tra Libera e Tiziano: 
-) ci sono due modalità di accesso ai dati giornalieri ARPAE: il vecchio Json è ormai lavorato da Libera e manca poco per terminare, il nuovo metodo forse è più comodo per estrarre dati ma ce ne siamo accorti solo ieri. Si decide di continuare con il vecchio metodo 
-) si discute come procedere in giornata:
    a) hyp1: creare pagina in dashboard con presentazione di valori per stazione (in futuro per comune)
    b) hyp2: sistemare la creazione della tabella dati giornalieri da upgradare day by day
-) revisione dei metodi di lavoro del gruppo: abbiamo lavorato bene ma siamo stati troppo separati in ciò che abbiamo fatto, serve un controllo di tutti su tutti (tiziano ha fatto bene? qualcuno ha controllato? Ha cappellato? ) 
-) dovremmo aumentare la quota di peer-programming in modo che tutti abbiano visibilità su tutto.

Libera: json + python, l'interrogazione dell'api in locale interroga ARPAE direttamente su base giornaliera senza dover scaricare anche dati non recenti. al momento ancora in locale da portare su azure tramite function app

Giovedi 30 luglio 2026
----------------------
meet allineamento dalle 10 alle 12 con task assegnate discusso sul lavoro fatto da fare e incontro clienti giorno precedente, allineato Alessandra 

Vanessa: lavorato su powerbi, generato slide con ia per integrazione presentazione soglie sforamenti legge ue, condiviso il lavoro fatto su slack

Tiziano: documento con i valori di soglia dei 5 inquinanti recuperato da sito eur-lex Gazzetta Ufficiale dell'Unione Europea

Alessandra: sistemata la mappa delle centraline (azure map) e caricato il pbix aggiornato su git senza sovrascrivere il precedente (il nuovo file ha la data nel nome)

giovedì 13 agosto 2026
----------------------
[IMPORTANTE!!!] (Tiziano - promemoria) Come gestire i dati validati a 4 livelli di validazione progressiva? Il punto è: si aggiornano le tabelle di accumulo con i dati che vengono modificati o si mantiene memoria di tutto? Come si applica la ETL nel nostro caso "dinamico"?

