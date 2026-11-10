# Recupero dalla Live Activity — design

## Perché
Con l'iPhone bloccato si può solo segnare «Fatta». Per accorciare o allungare il recupero, o saltare il
riscaldamento, bisogna sbloccare e aprire l'app. Si vuole farlo dalla Live Activity e dalla notifica di fine recupero.

## Cosa fa
1. **Durante il recupero** (schermata bloccata e Dynamic Island espansa): «−15 s», «+15 s» e «Salta».
   - ±15 s spostano la fine del recupero e la notifica di fine, come i ±15 dell'app (`TimerRecupero.cambia`):
     se −15 porta la fine a adesso o prima, il recupero finisce.
   - «Salta» chiude il recupero subito e toglie la notifica in attesa (`TimerRecupero.ferma`).
2. **Durante il riscaldamento** (la Live mostra un movimento): «Salta» salta tutti i movimenti rimasti e la Live
   passa alla prima serie. Il salto è un campo nuovo dell'allenamento, `riscaldamentoSaltato` (predefinito `false`,
   decodifica tollerante, salvato subito). I movimenti non vengono segnati come fatti: nell'app la riga del
   riscaldamento dice «Saltato» invece di «0/6».
3. **Notifica di fine recupero**: azione «Ancora 30 s» (categoria `recupero`). Fa ripartire un recupero di 30 s
   senza aprire l'app (l'app parte in background, come per «Fatta»).
4. **Layout**: «Fatta» resta l'unico pulsante pieno (verde); gli altri sono secondari (capsula chiara). Il conto
   alla rovescia ha la riga tutta per sé con i pulsanti accanto, niente riga in più: non si taglia.

## Come
- Intent nuovi in `Condiviso/AttivitaAllenamento.swift` (`isDiscoverable = false`): `CambiaRecuperoIntent(secondi)`,
  `SaltaRecuperoIntent`, `SaltaRiscaldamentoIntent`. Chiamano gli aggancio `AzioniLive.cambiaRecupero`,
  `.saltaRecupero`, `.saltaRiscaldamento`, impostati in `FormaApp.init`; dopo l'azione `aggiornaEAttendi()` e
  l'attesa della notifica.
- `StatoAllenamentoLive.da` non mostra il riscaldamento se `riscaldamentoSaltato`.
- `Notifiche.categoriaRecupero` con l'azione `ancora30`, registrata all'avvio; la notifica di fine recupero la usa.
  Il delegato delle notifiche chiama `AzioniLive.ancora30`, che avvia 30 s sul timer.
- `ferma()` non dimentica più l'aggiunta della notifica in corso: chi aspetta (`attendiNotifica`) sa che la notifica
  è stata tolta davvero.
- Stringhe nuove a mano in entrambi i `Localizable.xcstrings`, en ed en-GB.

## Non fa
- Niente scelta di durate diverse da 15 s e 30 s. Niente «Salta» sulle serie. Niente altro sulla notifica.

## Non verificabile senza iPhone vero
Aspetto e altezza della Live sulla schermata bloccata, tocco dei pulsanti con l'app sospesa, azione della notifica
con l'app chiusa.
