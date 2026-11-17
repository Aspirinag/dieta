# Controllo generale di Forma — regole comuni (10/11/2026)

Sei uno di sei agenti che controllano l'app **Forma** (iOS, SwiftUI: dieta + palestra) ognuno per un'area.
Lo scopo è **dire cosa non va**. Non si corregge niente adesso: le correzioni si fanno dopo, punto per punto, con l'utente.

## Dove sta il codice
- Copia di `main` da leggere: `/Users/rl/app-iphone/dieta-controllo` (commit 45bcb35). Leggi prima `CLAUDE.md` e `README.md`.
- App iOS in `iOS/` (target Forma, RecuperoWidget, FormaTests, FormaUITests; codice condiviso in `iOS/Condiviso`).
- Web app in `index.html` (stesso JSON della dieta), script in `scripts/`, CI in `.github/workflows/`.

## Cosa è già stato fatto (non ripeterlo)
- Controllo precedente in `/Users/rl/app-iphone/dieta-audit/` (`audit-dieta.md`, `audit-palestra.md`, `audit-giro.md`, `audit-concorrenti.md`, `revisione-23-26.md`). I problemi lì elencati sono stati corretti nelle PR #23–#30, già in `main`. Leggili per non rifare lo stesso lavoro; segnala solo se una correzione **non regge**.
- Minori già noti e rimandati (controlla se valgono ancora, non riscoprirli):
  `Backup.esporta` usa `try? ?? Data()`; il caso `.illeggibile` riprogramma i promemoria di fabbrica; il cardio può contare due volte (a mano + Watch);
  spesa: «2 x 50 g», «grammi» contro «g», plurali (fetta/fette); aggiungere una data di fine a un piano lascia chiuso il precedente;
  il delegate della pagina PDF non controlla quale pagina risponde; la Live Activity riappare dopo lo swipe quando l'app torna attiva (voluto).

## Divieti
- **Non modificare** `/Users/rl/app-iphone/dieta-controllo` né gli altri worktree. Niente commit, branch, push, PR, merge. **Mai `git stash`.**
- Se ti serve provare un bug con un test, crea una copia tua: `git -C /Users/rl/app-iphone/dieta worktree add --detach /Users/rl/app-iphone/dieta-controllo-<area> origin/main`, lavora lì, e alla fine toglila con `git -C /Users/rl/app-iphone/dieta worktree remove --force <percorso>`.
- Non installare niente sul Mac, non toccare impostazioni di sistema, non mandare dati fuori (le ricerche web vanno bene, senza dati personali).
- Non lanciare altri agenti.

## Simulatore e build (il Mac è condiviso con gli altri agenti)
- Usa **solo** il simulatore che ti è assegnato nel tuo compito (UDID) e una `-derivedDataPath` tua dentro
  `/private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/controllo-<area>/`. File temporanei solo lì.
- La suite intera è verde su `main` (CI): **non rilanciarla tutta**. Lancia solo i test che ti servono (`-only-testing:`), in background, con l'output in un file di cui leggi la coda.
- Se il simulatore muore con «signal kill», riprova una volta.
- Dati di prova: argomenti di avvio `-demo -tab oggi|dieta|allenamento|progressi|inCorso|impostazioni`, `-vista spesa` (con `-tab dieta`).

## Come si prova un difetto
Un difetto va nella lista solo se l'hai **verificato**: letto il codice riga per riga fino all'effetto, oppure riprodotto con un test o nel simulatore.
I sospetti non verificati vanno in una sezione a parte «Da verificare». Niente consigli generici («aggiungere più test», «migliorare la UX»): solo cose concrete.

## Il rapporto
Scrivilo in italiano semplice in `/Users/rl/app-iphone/dieta-audit/controllo-2/<area>.md`:

1. **In breve** (5 righe): come sta l'area.
2. **Cosa non va**, dal più grave. Per ogni punto:
   - titolo corto; **gravità** alta / media / bassa;
   - **dove** (`file:riga`);
   - **cosa succede a chi usa l'app** (uno scenario concreto);
   - **prova** (come l'hai verificato);
   - **correzione proposta** e **sforzo** (piccolo / medio / grande).
3. **Da verificare** (sospetti senza prova).
4. **Cosa funziona bene** (breve, solo cose non ovvie).

Gravità: *alta* = perdita di dati, crash, numero sbagliato su dieta o allenamento, rischio legale o di rifiuto dall'App Store, funzione che non va; *media* = comportamento sbagliato ma aggirabile; *bassa* = rifinitura.

## Messaggio finale
Al massimo 10 righe: percorso del rapporto, quanti punti per gravità, i 3 più importanti.
