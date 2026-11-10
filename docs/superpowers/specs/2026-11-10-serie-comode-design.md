# Serie comode: kg e ripetizioni senza tastiera

Ramo `serie-comode`, parte da `logica-allenamento` (PR #25). Fonti: richiesta dell'utente e `dieta-audit/audit-giro.md` (problemi 1-4).

## Problema
In allenamento si scrivono kg e ripetizioni con la tastiera: lenta, copre la lista, con le mani sudate è scomoda.
Inoltre VoiceOver non vede la spunta della serie, la conferma «Finire l'allenamento?» e i pulsanti di olio e acqua.

## Cosa cambia
1. **Niente tastiera.** Nella riga di ogni serie kg e ripetizioni sono due caselle da toccare (non più campi di testo).
   Il valore è già scritto (quello dell'ultima volta, come oggi).
2. **− e +** sotto la serie attiva, alti almeno 44 pt: kg ±2,5, ripetizioni ±1, mai sotto 0. A corpo libero i kg restano come oggi.
3. **Rotella.** Toccando una casella si apre un foglio basso con una rotella: kg da 0 a 300 a passi di 0,5 (se il valore attuale non è multiplo di 0,5, per esempio 37,25, compare anche quello), ripetizioni da 0 a 50 (se il valore è fuori scala compare anche quello).
4. **Svuotare.** Con − e + non si può svuotare un campo: il foglio ha il pulsante «Svuota». Svuotare una serie fatta le toglie la spunta (regola già in vigore). Alla spunta con un campo mancante si apre la rotella di quel campo, al posto della tastiera.
5. **Logica pura** in `PassoSerie` (limiti, elenco della rotella, arrotondamenti), provata in FormaTests.

## VoiceOver
- Cerchio di spunta: pulsante con etichetta «Segna la serie 2 di 4» e valore fatta / da fare.
- Conferma di «Fine»: «Finisci e salva» raggiungibile e «Annulla» visibile.
- − / + e rotella con etichette chiare («Togli 2,5 kg», «Kg, serie 2»).
- Oggi: ogni cucchiaino d'olio e ogni bicchiere d'acqua è un pulsante («Olio, cucchiaino 3 di 6» + fatto / da fare).
- Sotto l'allenamento a tutto schermo la schermata Oggi è nascosta a VoiceOver.

## Fuori portata
Nessun cambio al modello dati né al JSON. Il recupero e la spunta restano come in `logica-allenamento`.
