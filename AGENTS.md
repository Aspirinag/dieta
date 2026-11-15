# Forma — istruzioni per agenti diversi da Claude (es. modello locale con opencode)

Leggi prima `README.md` (cos'è l'app e com'è fatta) e `CLAUDE.md` (regole e comandi): valgono anche per te,
tranne le parti su subagent, skill e scelta del modello, che riguardano solo Claude Code.

## Regole in breve
- Rispondi e scrivi commit in **italiano** semplice.
- **Mai lavorare su `main`** (è protetto: si entra solo con una PR). Prima di modificare: `git switch -c <argomento>`.
- Una modifica piccola e mirata per volta. Non riscrivere file interi, non rinominare campi del JSON della dieta.
- Non toccare: `.github/`, `iOS/Forma.xcodeproj/project.pbxproj`, `vendor/`, la storia git (niente force-push, niente `git stash`).
- Dopo una modifica Swift lancia i test (comando in `CLAUDE.md`); se falliscono, sistemali o annulla la modifica.
- Dopo una modifica a `index.html` lancia `node scripts/controlla-lettore.mjs` e `node scripts/prova-dati-web.mjs`.
- Alla fine: `git push -u origin <branch>` e `gh pr create`. Non unire la PR: la controlla e la unisce l'utente.
- Non scrivere email, nomi reali o dati di salute in file, commit o PR.
