# Live Activity dell'allenamento — design

## Perché
Oggi la Live Activity c'è solo durante il recupero (conto alla rovescia). In palestra, con l'iPhone bloccato,
si vuole vedere **che esercizio e che serie fare adesso** e **cosa viene dopo**, e poter **segnare la serie fatta**
senza sbloccare e aprire l'app.

## Cosa fa
Una sola Live Activity per tutto l'allenamento in corso (sostituisce quella del solo recupero):
- parte quando c'è un allenamento in corso (anche all'avvio dell'app se ce n'era uno salvato), si chiude quando
  l'allenamento finisce o viene scartato;
- mostra: nome dell'allenamento e da quanto dura (cronometro che scorre da solo);
  l'esercizio della **serie attiva** con «Serie 2 di 4», i kg × ripetizioni proposti (gli stessi che la spunta
  nell'app userebbe: i campi della serie, altrimenti quelli della serie precedente, a corpo libero kg 0);
  «Poi: <esercizio>» = il prossimo esercizio con serie aperte (`PercorsoAllenamento.prossimoAperto`), oppure
  «Ultimo esercizio»;
- durante il recupero: conto alla rovescia e barra (come oggi). Scaduto il recupero con l'app sospesa
  (`staleDate` = fine del recupero) sparisce il conto e resta la serie da fare con «Recupero finito»;
- con tutte le serie fatte: «Tutte le serie fatte» e invito ad aprire Forma per finire;
- **pulsante «Fatta»** (spunta) sulla schermata bloccata e nella Dynamic Island espansa: segna la serie mostrata
  con i kg × ripetizioni mostrati e fa partire il recupero, esattamente come la spunta nell'app. Se mancano le
  ripetizioni o i kg (nessun valore né precedente), il pulsante non c'è e c'è scritto di aprire l'app.

## Come (decisioni prese)
- Stato condiviso in `iOS/Condiviso/AttivitaAllenamento.swift`: `StatoAllenamentoLive`, `AttivitaAllenamento`,
  `SegnaSerieIntent` (`LiveActivityIntent`, parametro = id della serie) e l'aggancio `AzioniLive.segna`.
  L'intent gira nel processo dell'app (anche se iOS la avvia in background): l'app imposta `AzioniLive.segna`
  in `FormaApp.init`. Nel widget l'aggancio resta vuoto e non serve.
- La serie attiva usa `SerieAttiva.trova` con riferimento = l'ultima serie spuntata (dall'app o dalla Live
  Activity), tenuta in `Palestra` senza salvarla su file.
- La Live Activity si aggiorna senza dipendere da `onChange` delle viste (in background le viste non si
  aggiornano): un oggetto dell'app osserva `palestra.stato.inCorso`, `ultimaSerie` e `timer.stato`
  (Observation) e applica lo stato; l'intent dopo la spunta salva subito (`salvaOra`) e aggiorna.
- Solo aggiornamenti locali (niente push). Aggiornamenti uguali non si mandano.
- L'estensione resta il target `RecuperoWidget` (niente modifiche al `.pbxproj`); `AttivitaRecupero` sparisce.
- Testi in italiano con traduzione inglese in `RecuperoWidget/Localizable.xcstrings` (e in quello dell'app per
  il titolo dell'intent).

## Non fa
- Niente modifica di kg/ripetizioni dalla schermata bloccata (solo «Fatta» con i valori proposti).
- Niente fine allenamento dalla Live Activity.
- Niente notifiche push.

## Lasciato a chi costruisce
Disposizione esatta della vista bloccata e della Dynamic Island, purché leggibile in chiaro/scuro e coerente
con `Colori` (verde solo per il pulsante «Fatta» e lo stato fatto).
