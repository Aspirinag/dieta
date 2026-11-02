# Allenamenti dall'Apple Watch (app Salute)

## Perché
Registro gli allenamenti sul Watch Ultra, ma spesso non li segno in Forma. Cammino molto e le camminate valgono come allenamento.

## Obiettivi
- A fine allenamento di palestra sul Watch, notifica "Registra sessione palestra?" se in Forma non c'è ancora niente per quel giorno. Toccandola si apre Allenamento.
- Durata, calorie attive e battito medio del Watch agganciati all'allenamento registrato in Forma (anche se fatto dal vivo).
- Camminate dal Watch registrate da sole come cardio "Camminata" (minuti e km), visibili in Oggi, calendario e storico.

## Non obiettivi
- Nessuna app per il Watch, nessuna scrittura su Salute (solo lettura).
- Nessun conteggio passi giornaliero (solo allenamenti avviati sul Watch).

## Approcci
1. Solo promemoria da Salute.
2. **Promemoria + dati del Watch dentro Forma + camminate automatiche (scelto da Claude su richiesta):** il Watch diventa parte dell'app, non solo un allarme.
3. Posizione della palestra: scartato, c'è il Watch e registro sempre.

## Mie scelte (correggibili)
- Palestra = allenamenti Watch di tipo forza tradizionale, forza funzionale, cross training, core, HIIT.
- Camminate: tipo "Camminata" ed "Escursionismo", **almeno 20 minuti**, importate senza chiedere; si possono eliminare come le altre sessioni cardio. Non si importano due volte (si salva l'identificativo dell'allenamento Salute).
- Corsa/bici/nuoto dal Watch: importati anch'essi come cardio, stessa regola (costa zero in più).
- Promemoria palestra: solo se quel giorno non c'è un allenamento pesi in Forma; uno per allenamento Watch.
- Aggancio dati: un allenamento Forma prende i dati del Watch che si sovrappone di più nel tempo.

## Vincoli
- HealthKit è disponibile anche con l'account sviluppatore gratuito (tabella Apple "Supported capabilities iOS", colonna Apple Developer).
- Oggi la CI crea una .ipa non firmata: gli entitlement (HealthKit, background delivery) vanno incorporati con una firma ad hoc in CI, altrimenti spariscono quando la si firma per installarla.
- La notifica in background arriva quando iOS consegna l'aggiornamento di Salute (di solito entro pochi minuti, non garantito al secondo).

## Verifica
Build in CI; nel simulatore non ci sono allenamenti Watch, quindi dati di prova in modalità demo per le schermate. Prova vera sull'iPhone dopo l'installazione.
