# Controllo funzione — Forma

Simulatore: iPhone 17 (2D568462-F252-4BE6-8BE1-DADAFF61C091), build Debug di `main` (45bcb35), una sola build e una sola schermata.

## 1. In breve
- L'app fa quello che promette: i flussi letti nel codice (Oggi, PDF, Spesa, Palestra, Progressi, Impostazioni, promemoria, backup) sono coerenti e hanno messaggi per gli stati vuoti e per gli errori.
- L'icona c'è, è collegata al target ed entra nella build, in versione chiara, scura e tinted.
- Trovato 1 solo difetto di funzione (media): il promemoria del pagamento della palestra è acceso di fabbrica anche per chi non va in palestra.
- Due rifiniture basse (backup, icona di riserva).
- Non ho aperto nel simulatore i flussi palestra, PDF e backup: li ho letti nel codice; sono coperti dai test UI esistenti.

## 2. Cosa non va

### 2.1 Promemoria e avviso «si paga la palestra» accesi per tutti — gravità media
- **Dove**: `iOS/Forma/Palestra/ModelliPalestra.swift:348` e `:371` (`pagamentoAttivo = true` di fabbrica); `iOS/Forma/BenvenutoView.swift:73` (`palestra.stato.pagamentoAttivo = consentite`); `iOS/Forma/HomeView.swift:112-118`; `iOS/Forma/Palestra/ArchivioPalestra.swift:438-444`.
- **Cosa succede**: chi usa solo la dieta, al benvenuto lascia i promemoria accesi e consente le notifiche. Forma accende anche il pagamento della palestra. Da 7 giorni prima del giorno 1 del mese compare in Oggi «Oggi si paga la palestra», con il tasto «Segna come pagato». Il primo del mese arriva anche la notifica «Palestra». Il testo del benvenuto dice che il pagamento della palestra si può *aggiungere* in Impostazioni, quindi l'utente se lo aspetta spento. Chi non ha mai usato la palestra non ha motivo di vederlo.
- **Prova**: lettura del codice fino all'effetto. Il default è `true`, il benvenuto lo imposta a `true` quando le notifiche sono consentite, `promemoriaPagamento` mostra il riquadro se `attivo`. Schermata del benvenuto vista nel simulatore (il testo del footer è quello descritto).
- **Correzione proposta**: default `false` e nel benvenuto non toccare `pagamentoAttivo`. Si accende solo da Impostazioni → Palestra, o quando l'utente registra il primo allenamento. Attenzione ai backup già esistenti: decodificano con default `true` quando la chiave manca, quindi va deciso se mantenere questo comportamento.
- **Sforzo**: piccolo.

### 2.2 `Backup.esporta` ricalcola il JSON a ogni ridisegno — gravità bassa
- **Dove**: `iOS/Forma/Dieta/ImpostazioniSezioni.swift` (sezione backup, `ShareLink(item: FileBackup(dati: Backup.esporta(...)))`).
- **Cosa succede**: aprendo Impostazioni → Backup, la codifica dell'intero archivio (dieta e palestra) viene rifatta a ogni ridisegno. Con anni di dati può rallentare. (Si aggiunge al già noto `try? ?? Data()`.)
- **Prova**: lettura del codice. Non misurato.
- **Correzione proposta**: calcolare i dati solo al tocco di «Esporta».
- **Sforzo**: piccolo.

### 2.3 PNG di riserva dell'icona con canale alfa — gravità bassa
- **Dove**: app compilata, `AppIcon60x60@2x.png` (`hasAlpha: yes`).
- **Cosa succede**: è il file usato dai sistemi più vecchi. Lo sfondo dell'icona è pieno (`fill` solido in `icon.json`), quindi non si vede trasparenza. Resta un rischio solo per i controlli di App Store Connect sull'icona 1024 (che qui non esiste come file).
- **Prova**: `sips -g hasAlpha` sul file nella build.
- **Correzione proposta**: nessuna per ora; da riguardare se l'invio all'App Store segnala l'icona.
- **Sforzo**: piccolo.

## 3. Da verificare
- Promemoria sul dispositivo vero: ho letto la programmazione (id `mattino`, `pasti`, `acqua-<minuti>`, `pagamento`, `recupero`), la rimozione dei vecchi e la richiesta del permesso. Non ho verificato la consegna reale delle notifiche agli orari scelti.
- Importa PDF, Palestra (avvia, recupero, termina), esporta/importa backup: letti nel codice, non provati nel simulatore.
- Icona: aspetto reale nelle tre varianti sulla Home. Confermata l'esistenza delle varianti nella build, non ho guardato l'immagine. Il file `icon.json` non ha varianti scure o tinted esplicite: iOS le ricava dai livelli.

## 4. Cosa funziona bene
- **Icona**: esiste solo `iOS/Forma/AppIcon.icon` (Icon Composer: sfondo solido, tre livelli SVG). Non c'è `AppIcon.appiconset`, e va bene così. `ASSETCATALOG_COMPILER_APPICON_NAME = AppIcon` è impostato in Debug e Release (`project.pbxproj:446` e `:478`). La cartella è inclusa nel target dal gruppo sincronizzato (objectVersion 77). Nella build: `Info.plist` ha `CFBundleIconName = AppIcon`, `Assets.car` contiene le immagini `UIAppearanceLight`, `UIAppearanceDark` e `ISAppearanceTintable`.
- **Primo avvio senza dati**: il benvenuto spiega prima di chiedere il permesso notifiche (visto nel simulatore). Oggi mostra «Nessun piano per oggi» con il tasto «Carica il piano alimentare (PDF)». Spesa ha lo stato vuoto con spiegazione. Progressi mostra «Nessun allenamento» con il testo di spiegazione. Il giorno senza pasti dice «Nessun pasto per questo giorno».
- **Promemoria**: il permesso si chiede quando si accende un promemoria. Se è negato, l'interruttore torna spento con il messaggio su come abilitarlo. La riprogrammazione è serializzata e toglie i vecchi promemoria. Si riprogramma anche se cambia la lingua. Le notifiche si cancellano da sole spegnendo l'opzione.
- **Import PDF**: dà un errore chiaro se i giorni trovati non sono 7 o se mancano i valori della BIA, e propone la via manuale.
- **Backup**: l'importazione chiede conferma, spiega cosa sostituisce e riprogramma i promemoria dopo l'importazione. Un backup della web app non spegne né riaccende i promemoria di Forma.

## Segnalato dall'utente (15/11)
- **Media — icona: forme poco definite.** `iOS/Forma/AppIcon.icon/icon.json`. Probabili cause: tutti e tre i livelli hanno `"glass": true` (il vetro Liquid Glass ammorbidisce i bordi e aggiunge riflessi); ombra `neutral` a 0.5; forme piccole (quadrato 220 px su 1024, cerchio r=110, circa il 20% del lato); colori medi su fondo crema chiaro (ocra #D6A445 su #F3EFE6 ha poco contrasto). Correzione: togliere il vetro o ridurlo, ingrandire le forme (~30% del lato), colori più saturi o fondo più scuro, ombra più leggera. Sforzo piccolo. Da provare in Icon Composer guardando la resa a 60 pt.
