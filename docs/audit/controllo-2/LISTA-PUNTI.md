# Forma — lista unica dei punti (giudice, 15/11/2026)

Fonte: i 6 rapporti di questa cartella (codice-dieta, codice-palestra, funzione, design, legale, sicurezza), sul commit `45bcb35`.
Qui i doppioni sono uniti, i punti che non reggono sono scartati e la gravità è rivista per l'effetto reale: app personale, repo pubblico, prova futura con un nutrizionista, forse App Store.

**Totale: 38 punti — 5 alta, 11 media, 22 bassa.** 9 pacchetti di lavoro. 7 decisioni tue (in fondo).

Percorsi: `Forma/...` = `iOS/Forma/...`.

## Tabella dei punti (in ordine di priorità)

| N | Gravità | Area | Cosa non va | Dove | Sforzo | Pacchetto |
|---|---|---|---|---|---|---|
| 1 | alta | Dieta | Se rinomini un pasto (o arriva un piano nuovo con nomi diversi) le spunte di quel pasto spariscono per sempre | `Forma/Dieta/Archivio.swift:279-297` | medio | A |
| 2 | alta | Web app | Un backup sbagliato (anche solo ritoccato a mano) cancella i dati e lascia la pagina bianca per sempre | `index.html:1089-1093`, `:217`, `:880`, `:166-172`, `:1101` | medio | B |
| 3 | alta | Legale | Manca la frase «non è un dispositivo medico, non sostituisce il nutrizionista» (serve già per la prova con i pazienti) | assente; da mettere in `Forma/BenvenutoView.swift`, Impostazioni, README | piccolo | C |
| 4 | alta (solo App Store) | Legale | Manca il file `PrivacyInfo.xcprivacy`: App Store rifiuta il caricamento | nessun file; `UserDefaults` in `Forma/Comune/Notifiche.swift:50-53` e altri 4 | piccolo | C |
| 5 | alta (App Store), media (nutrizionista) | Legale | Manca una pagina privacy pubblica (obbligatoria con Salute); nella web app manca la riga «dati solo in questo browser» | nessun file; `iOS/Forma.xcodeproj/project.pbxproj:456`; `index.html` | piccolo | C |
| 6 | media | Web app | Un file «backup» costruito apposta fa girare codice nella pagina e può leggere peso, BIA e pasti | `index.html:883`, `:761-763`, `:700-708`, `:690-693`, `:857`, `:666` | medio | B |
| 7 | media | Privacy | La tua email personale è pubblica in 31 commit e continua a comparire a ogni PR unita | metadati dei commit (impostazioni GitHub) | piccolo (impostazione) / grande (storia) | G |
| 8 | media | Privacy | Nomi veri di due persone e nota personale del nutrizionista scritti nella web app pubblica e in tre documenti | `index.html:146`, `:149-154`; `scripts/prova-dati-web.mjs:54`; `docs/superpowers/specs/2026-11-05-web-app-allineata-design.md:5`; `docs/superpowers/plans/2026-11-05-web-app-allineata.md:24` | piccolo | B |
| 9 | media | Dieta | «Importa backup» sostituisce tutto senza tenere una copia: file sbagliato = mesi di dati persi | `Forma/Comune/Backup.swift:26-39` | piccolo | A |
| 10 | media | Dieta | Il modulo misure accetta qualsiasi numero (peso 800) e svuota in silenzio i campi che non riesce a leggere | `Forma/Dieta/EditorMisura.swift:60-64`, `:106-116` | piccolo | A |
| 11 | media | Palestra | La rotella si ferma a 300 kg e 50 rip: plank da 60 s, pesi grandi e dischi da 1,25 kg non si scrivono | `Forma/Palestra/SpuntaSerie.swift:54-56`; `AllenamentoInCorsoView.swift:913-983`; `AllenamentoView.swift:319-327` | piccolo | D |
| 12 | media | Palestra | Massimale stimato sbagliato con 1 ripetizione (100 kg × 1 diventa 103,3 kg) | `Forma/Palestra/ModelliPalestra.swift:182` | piccolo | D |
| 13 | media | Promemoria | L'avviso «si paga la palestra» è acceso anche per chi usa solo la dieta | `Forma/Palestra/ModelliPalestra.swift:348`, `:371`; `Forma/BenvenutoView.swift:83` | piccolo | E |
| 14 | media | Icona | Forme poco definite (segnalato da te): vetro su tutti i livelli, forme piccole, poco contrasto | `Forma/AppIcon.icon/icon.json` e `Assets/*.svg` | piccolo | F |
| 15 | media | Design | Su iOS 18 la data sparisce da Oggi, Dieta e dettaglio pasto (tu hai iOS 26, i pazienti forse no) | `Forma/HomeView.swift:42`, `:419-421`; `Dieta/DietaView.swift:50`; `Dieta/DettaglioPastoView.swift:23` | piccolo | H |
| 16 | media | Legale | Il repo pubblico non ha una licenza: nessuno sa cosa può fare col codice | nessun `LICENSE`, `README.md` | piccolo | C |
| 17 | bassa | Web app | Nessuna protezione CSP: se entra codice estraneo può spedire fuori i dati | `index.html:3-12` | piccolo | B |
| 18 | bassa | Sicurezza | pdf.js vecchio (3.11.174) con falla nota; oggi non raggiungibile, basta una riga per chiuderla | `index.html:314`, `:366`; `Forma/Risorse/lettore.html:78`, `:130` | piccolo | B |
| 19 | bassa | Legale | pdf.js (Apache 2.0) senza copia della licenza e senza pagina «Licenze» nell'app | `vendor/`, `Forma/Risorse/`, Impostazioni | piccolo | C |
| 20 | bassa | GitHub | Il workflow iOS dà il permesso di scrittura a tutti i job, anche a quelli che non serve | `.github/workflows/forma.yml:17-18` | piccolo | G |
| 21 | bassa | GitHub | `main` non è protetto: ogni push va subito online sulla web app, anche con i controlli falliti | impostazioni del repository | piccolo | G |
| 22 | bassa | Dieta | Un elemento rovinato in un elenco del file fa perdere tutto l'elenco (solo con file modificati a mano) | `Forma/Dieta/Modelli.swift:402-406` | piccolo | A |
| 23 | bassa | Dieta | Misure o piani con data non valida vengono trattati come «oggi» | `Forma/Comune/Utilita.swift:63-67` | piccolo | A |
| 24 | bassa | Palestra | Esercizi a corpo libero: il record appare come «Peso massimo 0 kg × 12» | `Forma/Palestra/ArchivioPalestra.swift:619-631`; `ProgressiPalestraView.swift:205-208`; `StoricoView.swift:27-34` | piccolo | D |
| 25 | bassa | Palestra | Sessione del Watch completata a mano: il cronometro continua a salire in barra e schermata bloccata | `Forma/Palestra/TimerRecupero.swift:146`; `ArchivioPalestra.swift:225-242` | piccolo | D |
| 26 | bassa | Palestra | «Rimuovi esercizio» non ferma il recupero che quell'esercizio aveva fatto partire | `Forma/Palestra/AllenamentoInCorsoView.swift:493` | piccolo | D |
| 27 | bassa | Palestra | Se iOS chiude l'app durante il riposo, alla riapertura il conto alla rovescia non c'è più | `Forma/Palestra/TimerRecupero.swift:10-14`; `LiveAllenamento.swift:88-104` | medio | D |
| 28 | bassa | Palestra | Import dalla vecchia app Palestra: i giorni che hanno già un allenamento vengono saltati senza dirlo | `Forma/Palestra/ArchivioPalestra.swift:490-491` | piccolo | D |
| 29 | bassa | Palestra | Un allenamento del Watch salvato entro 60 s dall'ultima lettura arriva in ritardo e senza notifica | `Forma/Palestra/LetturaWatch.swift:36`; `Salute.swift:58-65`, `:78-82` | piccolo | D |
| 30 | bassa | Dieta | Con l'app aperta a mezzanotte, Dieta e Spesa restano sulla settimana vecchia | `Forma/Dieta/DietaView.swift:57-69`; `SpesaView.swift:57-63` | piccolo | I |
| 31 | bassa | Spesa | «2-3 fette» e «1/2 melone» vengono letti male nella lista della spesa | `Forma/Dieta/Archivio.swift:~423` (`vociSpesa`, `numeroQuantita`) | piccolo | I |
| 32 | bassa | Dieta | L'editor del piano lascia i pasti senza alimenti: in Oggi compare una riga vuota da spuntare | `Forma/Dieta/EditorPianoView.swift:148-158` | piccolo | I |
| 33 | bassa | Backup | Il backup viene ricalcolato a ogni ridisegno di Impostazioni (lento con anni di dati) | `Forma/Dieta/ImpostazioniSezioni.swift` (sezione backup) | piccolo | I |
| 34 | bassa | Pulizia | Codice mai usato: `aderenza()` e `giorniAllenati` | `Forma/Dieta/Archivio.swift:301`; `Forma/Palestra/ArchivioPalestra.swift:559` | piccolo | I |
| 35 | bassa | Design | I filtri della libreria esercizi sono alti 28 pt invece di 44: si sbaglia il tocco | `Forma/Palestra/LibreriaView.swift:111-125` | piccolo | H |
| 36 | bassa | Accessibilità | Il numero della serie non ha etichetta per VoiceOver («1, menu») | `Forma/Palestra/AllenamentoInCorsoView.swift:534-545` | piccolo | H |
| 37 | bassa | Design | Avvio scheda: pulsante verde in alto, triangolino grigio nelle righe sotto | `Forma/Palestra/AllenamentoView.swift:174-180` | piccolo | H |
| 38 | bassa | Accessibilità | La riga della spesa si tocca ma VoiceOver non la annuncia come bottone | `Forma/Dieta/SpesaView.swift:156-159` | piccolo | H |

## Cosa ho cambiato rispetto ai rapporti

**Doppioni uniti**
- Email nei commit: legale 6 + sicurezza 3 → punto 7.
- Nomi veri: legale 6 + sicurezza 4 → punto 8. Verificato: i nomi sono solo in `index.html`, script e documenti; **nel codice Swift non ci sono** (il rapporto legale citava `Archivio.swift`: non regge).
- Informativa privacy app (legale 3) + riga informativa web app (legale 7) + nota sul backup iCloud (sicurezza, da verificare) → punto 5: una sola pagina privacy.
- pdf.js: la falla (sicurezza 6) e la licenza (legale 5) restano due punti (18 e 19) perché si correggono in pacchetti diversi.

**Gravità riviste**
- Web app, pagina bianca (sicurezza 2): da media ad **alta**. È perdita di dati senza bisogno di un malintenzionato, e la web app è usata davvero.
- Nomi veri (sicurezza 4, bassa): **media**, perché insieme all'email identificano due persone legate a una app di salute.
- Manifesto privacy: alta **solo** per l'App Store; oggi non ha nessun effetto.
- Recupero che non sopravvive (palestra 4): resta bassa, ma lo sforzo è medio.

**Scartati**
- Icona di riserva con canale alfa (funzione 2.3): nessun effetto visibile, nessuna correzione proposta.
- HealthKit, dichiarazione di accesso (legale 8): è già a posto, resta solo una nota per App Store Connect.
- File di build e `.ipa` nella storia (legale 9): la sicurezza ha verificato che su GitHub non ci sono; la `.ipa` non contiene dati.
- Manifesto privacy per il widget (legale, da verificare): verificato, il widget **non** usa `UserDefaults`; basta il manifesto dell'app.
- Promemoria del mattino acceso senza scelta (dieta, da verificare): il benvenuto lo imposta in modo esplicito (`BenvenutoView.swift:81`), quindi per chi installa non succede. Resta solo il caso del backup vecchio senza il campo: va trattato nel pacchetto E.
- Team ID Apple pubblico: non è un segreto.

**Sospetti non provati (restano «da verificare», da guardare dentro il pacchetto indicato)**
- Possibile crash eliminando una voce nell'editor scheda (`AllenamentoView.swift:259-266`) → D, con un test UI.
- Import mentre il salvataggio è bloccato: sembra riuscito ma non viene salvato → A.
- Ancora di Salute scritta prima dell'importazione (`LetturaWatch.swift:40`) → D.
- «Precedente» sbagliato se lo stesso esercizio compare due volte → D.
- PDF enorme o che blocca la lettura: nessuna uscita dal riquadro «Lettura del PDF…» → B (stesso file `lettore.html`), solo se semplice.
- Reparti della spesa («Insalata di tonno» in frutta e verdura) → I, con i piani veri.
- Grafici e widget con testo molto grande → H, solo guardando sul simulatore.
- Gli altri due siti sulla stessa origine (`Aspirinag.github.io`, `Palestra`) non sono stati letti: se importano backup allo stesso modo valgono i punti 2 e 6.

## Pacchetti di lavoro (una conversazione, un branch, una PR ciascuno)

Ordine consigliato: **A → B → C → D → E → F → G → H → I**. A, B, F e G non toccano gli stessi file e possono partire insieme.

### A — Dieta: dati al sicuro
- **Punti:** 1, 9, 10, 22, 23 (+ sospetto «import con salvataggio bloccato»).
- **File:** `Forma/Dieta/Archivio.swift`, `Forma/Comune/Backup.swift`, `Forma/Dieta/EditorMisura.swift`, `Forma/Dieta/Modelli.swift`, `Forma/Comune/Utilita.swift`, test in `FormaTests`.
- **Ordine:** 1 (con test «rinomina di un pasto con giorni già spuntati») → 9 → 10 → 22 → 23.

### B — Web app: backup sicuro + XSS + nomi neutri
- **Punti:** 2, 6, 8, 17, 18.
- **File:** `index.html`, `Forma/Risorse/lettore.html` (solo la riga `isEvalSupported`), `scripts/prova-dati-web.mjs`, i due documenti in `docs/superpowers/`.
- **Ordine:** 2 e 6 insieme (ricostruire i dati campo per campo, provare il disegno prima di salvare, schermata di soccorso) → 17 (CSP) → 18 → 8.
- **Attenzione:** non rinominare gli identificativi interni `raffaele`/`alessandra` dei dati già salvati; cambia solo ciò che vede un visitatore nuovo. Dipende dalla decisione 3.

### C — Privacy e App Store
- **Punti:** 3, 4, 5, 16, 19.
- **File:** nuovo `Forma/PrivacyInfo.xcprivacy`, `Forma/BenvenutoView.swift`, `Forma/Dieta/ImpostazioniSezioni.swift` (avvertenza e pagina «Licenze»), `Localizable.xcstrings` (italiano e inglese), nuova pagina `privacy.html`, `README.md`, `LICENSE`, `vendor/LICENSE-pdfjs`.
- **Ordine:** 3 (serve già per il nutrizionista) → 5 → 4 → 19 → 16.
- **Dopo B** (tocca `index.html` per la riga «dati solo in questo browser»). Dipende dalle decisioni 4 e 6.

### D — Palestra: rotella, massimale e numeri
- **Punti:** 11, 12, 24, 25, 26, 27, 28, 29 (+ i tre sospetti della palestra).
- **File:** `Forma/Palestra/SpuntaSerie.swift`, `AllenamentoInCorsoView.swift`, `AllenamentoView.swift`, `ModelliPalestra.swift`, `ArchivioPalestra.swift`, `ProgressiPalestraView.swift`, `StoricoView.swift`, `TimerRecupero.swift`, `LiveAllenamento.swift`, `LetturaWatch.swift`, `Salute.swift`.
- **Ordine:** 11 → 12 → 24 → 26 → 25 → 28 → 29 → 27 (per ultimo: è l'unico da provare su iPhone vero).

### E — Promemoria palestra spento di fabbrica
- **Punti:** 13 (+ caso del backup vecchio senza il campo `promemoria`).
- **File:** `Forma/Palestra/ModelliPalestra.swift`, `Forma/BenvenutoView.swift`, `Forma/Palestra/SezioniPalestra.swift`, test.
- **Dopo D** (stesso file `ModelliPalestra.swift`). Dipende dalla decisione 5.

### F — Icona
- **Punti:** 14.
- **File:** `Forma/AppIcon.icon/icon.json`, `Forma/AppIcon.icon/Assets/*.svg`.
- **Ordine:** togliere o ridurre il vetro → forme più grandi (circa 30% del lato) → più contrasto → ombra più leggera; guardare la resa a 60 pt, chiaro, scuro e tinted. Nessuna decisione richiesta prima di partire.

### G — GitHub: email privata, permessi, protezione di main
- **Punti:** 7, 20, 21.
- **File:** `.github/workflows/forma.yml`; il resto sono impostazioni di GitHub.
- **Ordine:** email privata nelle impostazioni dell'account → permessi del workflow → regola su `main`. Dipende dalle decisioni 1, 2 e 7.

### H — Design e accessibilità
- **Punti:** 15, 35, 36, 37, 38.
- **File:** `Forma/HomeView.swift`, `Forma/Dieta/DietaView.swift`, `DettaglioPastoView.swift`, `SpesaView.swift`, `Forma/Palestra/LibreriaView.swift`, `AllenamentoInCorsoView.swift`, `AllenamentoView.swift`.
- **Ordine:** 15 → 35 → 36 → 38 → 37. **Dopo D** (stessi file della palestra).

### I — Rifiniture dieta e spesa
- **Punti:** 30, 31, 32, 33, 34.
- **File:** `Forma/Dieta/DietaView.swift`, `SpesaView.swift`, `Archivio.swift`, `EditorPianoView.swift`, `ImpostazioniSezioni.swift`, `Forma/Palestra/ArchivioPalestra.swift`.
- **Dopo A, C e H** (stessi file).

## Decisioni tue

1. **Riscrivere la storia git per togliere l'email dai commit?** — Raccomando **no**: l'indirizzo è già stato copiato da chi indicizza GitHub e la riscrittura rompe PR, tag e release; attiva solo «email privata» da ora in poi (pacchetto G).
2. **Rendere il repo privato?** — Raccomando **no**, tienilo pubblico: la web app su GitHub Pages e lo script di installazione dipendono dal repo pubblico, e dentro non ci sono dati di salute né segreti; basta togliere i nomi.
3. **Togliere i nomi reali e la nota del nutrizionista dalla web app?** — Raccomando **sì**: un visitatore nuovo vede «Profilo 1» senza nota; chi la usa già non perde niente.
4. **Pubblicare una pagina privacy e la frase «non è un dispositivo medico»?** — Raccomando **sì, prima della prova con il nutrizionista**; per i pazienti chiedi anche al nutrizionista (o a un consulente) chi risponde dei dati: è l'unico punto che richiede un parere professionale.
5. **Promemoria «si paga la palestra» spento di fabbrica?** — Raccomando **sì**; per chi ha già dati resta acceso solo se ha registrato allenamenti o pagamenti.
6. **Licenza del repo** — Raccomando **«tutti i diritti riservati»** scritto nel README (nessuna licenza aperta), così resti libero per l'App Store; si può aprire più avanti, non il contrario.
7. **Bloccare i push diretti su `main`** (solo PR con il controllo verde) — Raccomando **sì**: gli agenti lavorano già con le PR, per te non cambia niente.

Per l'icona non serve una decisione adesso: il pacchetto F prepara una proposta e la guardi sull'iPhone.
