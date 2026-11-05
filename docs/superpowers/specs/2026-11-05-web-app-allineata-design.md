# Web app allineata a Forma (solo dieta) — progetto

## Perché

La web app (`index.html`, su GitHub Pages: https://aspirinag.github.io/dieta/) la usa la compagna dell'utente, dal suo iPhone, con il suo piano alimentare. Usa solo la dieta: carica il PDF del nutrizionista e guarda i pasti del giorno e della settimana, con le alternative («Oppure»). La palestra non le serve.

L'app per iPhone Forma nelle ultime settimane è cambiata molto (nuovo aspetto, testi rivisti, lettura del PDF corretta); la web app è ferma a ottobre. Lo scopo è che la sua dieta funzioni e si veda come in Forma.

## Obiettivi

1. **Lettura del PDF uguale a Forma.** La web app usa lo stesso codice di `iOS/Forma/Risorse/lettore.html` (`parseSchema`, `leggiSchemaPdf`, `parseBia`, `leggiBiaPdf`, con `PASTI` senza maiuscole e soglia della colonna al 40% della larghezza della pagina). Lo schema di prova (`Schema Dietetico Liguori Raffaele.pdf`, simile al suo) deve dare lo stesso risultato nei due lettori.
2. **Niente più divergenze.** Un controllo automatico (test in CI) fallisce se il codice di lettura in `index.html` e in `lettore.html` è diverso.
3. **Aspetto di Forma.** Stile iOS «a gruppi» (sfondo grigio di sistema, riquadri arrotondati), tema chiaro e scuro automatici, colore d'accento di Forma (`Colori.accento`), cerchi di spunta come in Forma, caratteri di sistema. Riferimento: le viste SwiftUI della dieta (`HomeView.swift`, `Dieta/DietaView.swift`, `Dieta/DettaglioPastoView.swift`, `Dieta/SpesaView.swift`, `Dieta/PianiView.swift`).
4. **Testi di Forma.** Stesse parole dell'app per le stesse cose (vedi `docs/revisione-testi.md` e `iOS/Forma/Localizable.xcstrings`): «piano alimentare», «Piani e misure», «Non riesco a leggere il PDF», ecc. Solo italiano.
5. **Alternative ben visibili.** Per ogni pasto si vedono tutte le alternative, come nel dettaglio del pasto di Forma.

## Non obiettivi

- Niente palestra, niente promemoria che richiedono notifiche native.
- Niente sincronizzazione tra telefoni: i dati restano nel browser; i backup restano lo stesso file di Forma.
- Niente inglese.

## Da non rompere (anti-obiettivi)

- **I suoi dati.** Restano nel `localStorage` con la stessa chiave e lo stesso formato: dopo l'aggiornamento riapre la pagina e ritrova piano, spunte e misure. Nessuna rinomina di campi (regola del repo: `dieta.json` compatibile con Forma).
- **Backup.** Un backup esportato da Forma si importa nella web app e viceversa, senza perdere campi (anche quelli che la web app non usa, es. `spesa_prossima`, promemoria con orari).
- **Uso da iPhone.** Funziona in Safari e aggiunta alla schermata Home (meta `apple-mobile-web-app-*` restano), con aree sicure e tocchi di almeno 44 pt.
- **L'«app» sulla schermata Home.** Se lei ha aggiunto la pagina alla Home, deve aprire la nuova versione senza fare niente e ritrovare i dati. Quindi:
  - indirizzo e percorso uguali (`https://aspirinag.github.io/dieta/`, `index.html` nella radice);
  - nessun service worker: iOS riscarica la pagina a ogni apertura, e GitHub Pages la tiene in cache al massimo 10 minuti;
  - i file in `vendor/` e l'icona mantengono gli stessi nomi; se un file cambia, il riferimento ha un parametro di versione (es. `pdf.min.js?v=2`);
  - i dati dell'app sulla Home sono separati da quelli di Safari e legati all'indirizzo: per questo l'indirizzo non cambia.
- Nessuna libreria nuova da internet: resta un file `index.html` più `vendor/`.

## Scelte già fatte

- Tutto resta in `index.html` (più `vendor/`); nessun passaggio di build.
- Si tiene quello che c'è (Oggi, Settimana con Spesa, Andamento con BIA, Dati/Impostazioni, profili, backup): nascosto o semplificato dove distrae, non tolto, così i backup restano completi.

## Decisioni dopo la rilettura (scelte di Claude, da controllare)

- **Piano già salvato:** resta com'è, nessuna migrazione. Sullo schema di prova il vecchio e il nuovo lettore danno un risultato identico (7 giorni, 4 pasti ciascuno), quindi il suo piano non cambia. Se in futuro vede errori, ricarica il PDF.
- **Nomi dei pasti:** si salvano come scritti nel PDF, come fa Forma. Le spunte e gli altri dati devono restare legati alle stesse chiavi di oggi.
- **Quante funzioni:** solo aspetto e testi nuovi su quello che c'è già, più le alternative ben visibili (obiettivo 5). Nessuna funzione nuova di Forma (es. editor del piano a mano).
- **Prova e pubblicazione:** si prova in locale (Safari del simulatore iPhone con un server sul Mac) dal branch. GitHub Pages pubblica `main`, quindi si unisce solo quando l'utente lo chiede. Per tornare indietro basta un `git revert` del merge.
- **Controllo in CI:** un workflow nuovo e leggero (Node su Ubuntu) che parte quando cambiano `index.html`, `iOS/Forma/Risorse/lettore.html` o lo script. Confronta il blocco tra due commenti marcatori (`// --- lettore: inizio ---` / `// --- lettore: fine ---`) nei due file, riga per riga, ignorando gli spazi a inizio e fine riga. Il wrapper base64 di `lettore.html` resta fuori dai marcatori.

## Lasciato a chi costruisce

- Come estrarre e confrontare il codice di lettura nel test (es. uno script Node in `scripts/` lanciato dalla CI, che confronta i blocchi tra due commenti marcatori).
- La disposizione precisa delle schede, purché le funzioni della dieta di Forma siano raggiungibili come in Forma.
- Il test della lettura del PDF di prova con Node e `vendor/pdf.min.js` (il PDF di prova è dell'utente: non va nel repo; si usa in locale).
