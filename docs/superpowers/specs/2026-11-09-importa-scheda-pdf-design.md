# Importa una scheda di allenamento da PDF

## Obiettivo
In Palestra si possono importare una o più schede (Routine) da un PDF.

## Comportamento
- Il testo del PDF si legge con PDFKit. `LettoreScheda.leggi(testo:libreria:)` è un componente puro: dal testo ricava le schede.
- Una riga «Scheda X», «Giorno N», «Allenamento X» o con un giorno della settimana apre una scheda. Il nome è la riga intera o la parte prima del «—».
- Una riga esercizio ha: nome, serie, ripetizioni, recupero (facoltativo), note (facoltative). Formati: «3 8-10», «3x10», «3 x 8-10», «3×12»; un solo numero vale min = max.
- Recupero: «2'», «1'30"», «90"», «90s», «1:30», «2 min», in secondi; se manca, 90.
- Ignorati: paragrafi liberi, intestazione «Esercizio Serie…», righe di continuazione delle note, nomi di esercizi citati nelle note.
- Abbinamento alla libreria: senza maiuscole, accenti e spazi doppi; prima esatto, poi il nome più lungo contenuto. Un nome sconosciuto diventa esercizio personalizzato nuovo (muscolo e attrezzo «altro»), aggiunto alla libreria con `nuovoEsercizio`.
- Interfaccia: «Importa da PDF» nel menu «+» di Palestra (accanto a «Nuova scheda») e nella sezione «Altro». Si sceglie il PDF, si vede l'anteprima (schede, esercizi, serie × ripetizioni, recupero, «nuovo»), «Importa» aggiunge le schede. Nome già usato: si aggiunge « (2)». Le schede esistenti non si toccano. Se non trova nulla: «Non ho trovato esercizi in questo PDF».
- I modelli salvati non cambiano.
