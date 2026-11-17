# Controllo legale di Forma (in lavorazione)

> Rapporto scritto man mano: i punti qui sotto sono già verificati. Le sezioni «In breve», «Da verificare», «Cosa funziona bene» e la lista di controllo finale arrivano alla fine.
> Non sono un avvocato: dove serve un parere professionale è scritto.
> Codice letto: `/Users/rl/app-iphone/dieta-controllo` (commit 45bcb35). Tre momenti: **A** oggi (uso personale), **B** prova con nutrizionista e pochi pazienti, **C** App Store.

## In breve

Per l'uso personale (A) e per la prova con pochi pazienti (B) l'app è in buone condizioni: dati solo sul telefono, nessun server, nessun font remoto, nessun cookie. Per l'App Store (C) mancano però quattro cose bloccanti: manifesto privacy, informativa privacy, avvertenza «non è un dispositivo medico» e una licenza del repo. Nel repo pubblico non ho trovato piani dieta reali né PDF di pazienti; ci sono i nomi propri tuoi e della tua compagna e la tua email Gmail nei metadati dei commit.

## Cosa non va

### 1. Manca PrivacyInfo.xcprivacy (rifiuto App Store) — gravità ALTA (momento C)
- **Dove:** nessun file `*.xcprivacy` nel repo (`git ls-files`); l'app usa `UserDefaults` in `iOS/Forma/Comune/Notifiche.swift:50-53`, `iOS/Forma/Palestra/Salute.swift:32`, `iOS/Forma/BenvenutoView.swift:88`, `iOS/Forma/Palestra/LetturaWatch.swift:21`, `iOS/Forma/Dieta/Archivio.swift:78`.
- **Cosa succede:** `UserDefaults` è una API «a motivazione obbligatoria». Senza manifesto, App Store Connect rifiuta il caricamento (errore ITMS-91053). Anche l'estensione RecuperoWidget ne ha bisogno se usa le stesse API.
- **Prova:** ricerca file e grep delle API (nessun uso di date dei file, spazio disco o `systemUptime` nel codice dell'app: grep vuoto, quindi basta la categoria UserDefaults, motivazione CA92.1). Dichiarare anche «dati raccolti: nessuno» e nessun tracciamento.
- **Correzione:** aggiungere `PrivacyInfo.xcprivacy` al target Forma (e al widget se serve), con UserDefaults CA92.1. **Sforzo:** piccolo.

### 2. Nessuna avvertenza «non è un dispositivo medico / non sostituisce il nutrizionista» — gravità ALTA (B e C)
- **Dove:** assente in tutta l'app (grep su `Localizable.xcstrings` per medico, avvertenza, disclaimer, sostituisce: nessun risultato). Il testo più vicino è `iOS/Forma/Dieta/DietaView.swift:78` («PDF del piano che ti ha dato il nutrizionista»). Nessuna frase nel README.
- **Cosa succede:** l'app calcola e mostra dieta, peso, BIA e calorie. Le linee guida App Store 1.4.1 (app di salute: informazioni accurate, invito a consultare un medico) e 5.1.3 (dati di salute) rendono questa avvertenza il minimo; nella prova con pazienti (B) il nutrizionista risponde del piano, ma l'app deve dire che non sostituisce il parere professionale e che i numeri (calorie, BIA) sono informativi.
- **Prova:** grep nell'app e nel README, nessuna frase.
- **Correzione:** una riga in Impostazioni e nella schermata di benvenuto («Forma non è un dispositivo medico e non sostituisce il parere del medico o del nutrizionista. Il piano è quello che ti ha dato il professionista.»), anche nel testo di App Store. **Sforzo:** piccolo.

### 3. Nessuna informativa privacy (obbligatoria per HealthKit e App Store) — gravità ALTA (C), media (B)
- **Dove:** nessun file/URL di informativa (grep «privacy» in README e docs: nulla). `iOS/Forma.xcodeproj/project.pbxproj:456` chiede la lettura di Salute (`NSHealthShareUsageDescription`), entitlement HealthKit in `iOS/Forma.entitlements`.
- **Cosa succede:** App Store Connect richiede un URL della privacy policy; per le app con HealthKit viene verificata e va dichiarato l'uso dei dati. In prova con pazienti (B) i dati di salute di altre persone (peso, BIA, dieta) sono dati particolari (art. 9 GDPR): serve dire che restano sul telefono e chi ne è titolare. Il README lo dice già («I dati restano sul telefono: niente account, niente server»): basta trasformarlo in una pagina pubblica. Verificato che nel codice dell'app non c'è nessuna chiamata di rete (grep `URLSession`, `http`: nessun risultato nelle viste); l'unica rete è la web app del punto 7.
- **Correzione:** pagina privacy breve (GitHub Pages va bene) con: dati su dispositivo, backup solo manuale in JSON (l'utente sceglie dove salvarlo), Salute letta e mai scritta né inviata, nessuna analisi. Poi compilare le «etichette privacy» di App Store Connect su «nessun dato raccolto». **Sforzo:** piccolo.

### 4. Nessuna licenza nel repo pubblico — gravità MEDIA (A, B, C)
- **Dove:** nessun `LICENSE` (`find`), nessuna riga di licenza nel README.
- **Cosa succede:** senza licenza il codice è «tutti i diritti riservati» ma pubblico: chiunque lo vede e nessuno sa cosa può fare. Il repo contiene anche `scripts/installa-iphone.sh` scaricato via `curl` da `main`, e la release con la `.ipa` pubblica (`.github/workflows/forma.yml:61`). Scelta tua: tenerlo riservato o dare una licenza (es. MIT).
- **Correzione:** decidere e aggiungere `LICENSE`; se si vuole che resti proprietario, anche una riga nel README. **Sforzo:** piccolo.

### 5. pdf.js (Apache 2.0) senza copia della licenza né NOTICE — gravità BASSA
- **Dove:** `vendor/pdf.min.js`, `vendor/pdf.worker.min.js` (Mozilla, 2023); copia anche dentro l'app (`iOS/Forma/Risorse`, il README la cita).
- **Prova:** l'intestazione `@licstart` con testo Apache 2.0 e copyright Mozilla è nei file; manca il file `LICENSE` Apache nel repo e nell'app.
- **Correzione:** aggiungere il testo della licenza in `vendor/LICENSE-pdfjs` e una pagina «Licenze» in Impostazioni (obbligo di attribuzione). **Sforzo:** piccolo.

### 6. Email e nomi personali nel repo pubblico — gravità MEDIA (A)
- **Dove:** `index.html:151-152` (profili predefiniti «Raffaele» e «Alessandra»); nei metadati di 31 commit l'email `lig.raffaele@gmail.com` (es. commit 5c7b681, merge della PR #1); in `.claude/agents/ui-checker.md` e nei documenti percorsi `/Users/rl/...` del Mac; in `project.pbxproj:392,426` l'ID del team Apple `X2A6Q72Y79` (non è un segreto, solo identificativo).
- **Cosa succede:** chiunque può leggere nome di battesimo tuo e della tua compagna, collegati a una app di dieta e salute, e la tua email personale. Non ci sono dati sanitari reali: nessun PDF o JSON di dieta nel tree (`git ls-files`) né nei dati di prova (`Demo.swift` ha alimenti generici). La compagna usa la web app dal repo pubblico: il suo profilo con i dati vive solo nel suo `localStorage`.
- **Prova:** grep email/nomi, `git log --format=%ae`. Le schermate `dark-*.png` sono solo nella storia (non aperte: presumibilmente dai dati demo, vedi «Da verificare»).
- **Correzione:** profili predefiniti neutri («Profilo 1», «Profilo 2») in `index.html` e `Archivio.swift` (attenzione alla compatibilità del JSON, vedi CLAUDE.md); per l'email, riscrivere la storia è invasivo: valutare se importa (Gmail già pubblica nei commit), altrimenti usare l'indirizzo noreply di GitHub da ora. **Sforzo:** piccolo (nomi), grande (storia).

### 7. Web app: nessun font o servizio di terze parti, ma niente informativa — gravità BASSA (GDPR)
- **Dove:** `index.html` (grep `googleapis|gstatic|<link|fetch(|XMLHttp|sendBeacon|analytics|cookie`: solo `apple-touch-icon`, `localStorage` alle righe 168-189, script locale `vendor/pdf.min.js`).
- **Cosa succede:** il font è quello di sistema (`font-family: -apple-system`), nessun Google Fonts, nessun cookie, nessuna analisi: nessun trasferimento di IP a terzi dal tuo codice. Resta che GitHub Pages registra gli IP nei propri log (cosa di GitHub, non tua). I dati di dieta e BIA stanno nel `localStorage` del browser, in chiaro: va detto (cancellare i dati del sito li perde, nessun backup automatico).
- **Correzione:** riga di testo nella web app che dice «dati solo su questo browser; esporta per fare un backup». Gli utenti (compagna) sono già a conoscenza. **Sforzo:** piccolo.

### 8. HealthKit: dichiarazione di accesso e motivazione — gravità BASSA (C)
- **Dove:** `iOS/Forma.entitlements` (healthkit, `healthkit.access` vuoto, `background-delivery` true); lettura di `iOS/Forma/Palestra/LetturaWatch.swift:51-53`; stringa in `project.pbxproj:456` presente; solo lettura (`toShare: []`, riga 57).
- **Cosa succede:** la stringa c'è e dice cosa serve. Il review dell'App Store controlla che HealthKit sia usato per qualcosa di visibile (lo è: allenamenti) e che i dati non vadano in iCloud/pubblicità (non vanno). Non serve `NSHealthUpdateUsageDescription` perché non scrive. Nota: esiste `InfoPlist.xcstrings` (contenuto non letto); la richiesta parte dalla schermata di benvenuto (`BenvenutoView.swift:88-91`), non da un gesto dell'utente sul momento (linea guida Apple HIG, consiglio non regola).
- **Correzione:** nessuna obbligatoria; in App Store Connect dichiarare «Salute e fitness: letto, non raccolto». **Sforzo:** piccolo.

### 9. Build di sviluppo e `.ipa` firmata ad hoc nel repo pubblico — gravità BASSA
- **Dove:** `git log --all -- 'iOS/build-dd/*'` mostra 4 commit con file di compilazione in passato; oggi 0 file (`git ls-files iOS/build-dd`). `.github/workflows/forma.yml:36-62` pubblica la `.ipa` come release pubblica.
- **Cosa succede:** niente dati personali, ma la storia contiene artefatti inutili e gli ID del progetto. La `.ipa` pubblica con HealthKit è scaricabile da chiunque (innocuo: non contiene dati).
- **Correzione:** nessuna urgente. **Sforzo:** piccolo.

## Da verificare

- **Manifesto del widget:** se `RecuperoWidget` usa `UserDefaults` o un gruppo app (non letto a fondo): servirebbe un manifesto anche lì.
- **SDK/librerie di terze parti:** non ho trovato pacchetti Swift (`Package.resolved`) né Capacitor attivo; vecchio `ios/App` è solo nella storia. Controllare con Xcode (non fatto: niente build).
- **Etichette privacy di App Store Connect** e testo di «Informazioni» dell'app: non sono nel repo, vanno scritte.
- **Informativa e consenso per il nutrizionista (B):** se il nutrizionista dà l'app ai pazienti, chi tratta i dati? (probabile risposta: l'utente solo, sul proprio telefono, ma serve un parere professionale).
- **Contenuto di `docs/ricerca` e delle schermate in storia:** letti solo con grep, non per intero (nessun nome di paziente trovato).
- **Lingua delle avvertenze** (italiano e inglese): l'app è localizzata.

## Cosa funziona bene

- Nessuna chiamata di rete nell'app e nessun font remoto nella web app: niente da dichiarare per tracciamento o trasferimenti.
- HealthKit solo in lettura, con motivazione scritta e tradotta.
- Nessun dato sanitario reale nei dati di prova e nel repo; il PDF di prova del 9/11 (generica scheda allenamento) non è più nel tree.
- Il README già dice con chiarezza «dati sul telefono, niente account, niente server».
- `ITSAppUsesNonExemptEncryption = NO` è già impostato (`project.pbxproj:454`).

## Lista di controllo prima dell'App Store

1. `PrivacyInfo.xcprivacy` (UserDefaults CA92.1, nessun tracciamento).
2. Avvertenza «non è un dispositivo medico» in app e nella scheda App Store.
3. Pagina privacy pubblica + URL in App Store Connect + etichette «nessun dato raccolto».
4. Licenza del repo e pagina «Licenze» (pdf.js Apache 2.0).
5. Profili predefiniti neutri; decidere sull'email nei commit.

