# Regole comuni per le correzioni (leggere per prime)

- Repo: /Users/rl/app-iphone/dieta (NON lavorare lì, NON toccare main).
- Crea il tuo worktree: `cd /Users/rl/app-iphone/dieta && git fetch -q origin && git worktree add -b <ramo> /Users/rl/app-iphone/dieta-<ramo> origin/main`, poi lavora SOLO lì.
- Leggi CLAUDE.md e README.md del repo. Italiano ovunque (codice, commenti, commit, PR).
- I rapporti con file:riga, prove e correzioni proposte sono in /Users/rl/app-iphone/dieta-audit/ (audit-dieta.md, audit-palestra.md, audit-giro.md). Test che dimostrano i bug: AuditDietaTests.swift e AuditPalestraTests.swift lì accanto (adattali: devono verificare il comportamento GIUSTO).
- Per ogni bug: prima il test che fallisce (FormaTests, Swift Testing come gli altri test), vedilo fallire, poi correggi, poi vedilo passare.
- Modelli Codable: decodifica tollerante, campi nuovi con predefinito. Il JSON della dieta resta compatibile con index.html.
- Stringhe nuove: aggiungile a iOS/Forma/Localizable.xcstrings A MANO nel formato esatto del file (`"chiave" : {` ... con en ed en-GB), MAI json.dump (riformatta tutto il file).
- Test: `cd iOS && xcodebuild test -project Forma.xcodeproj -scheme Forma -destination 'platform=iOS Simulator,name=iPhone 17e' -only-testing:FormaTests -derivedDataPath /private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/dd-<ramo> > /private/tmp/claude-501/-Users-rl/e1beabfc-0da9-4645-bc6c-bf9681184997/scratchpad/test-<ramo>.log 2>&1; tail -40 ...log`. Usa un derivedDataPath tuo. Se il simulatore va in crash ("signal kill"), riprova una volta.
- Fine: tutti i FormaTests verdi, commit (messaggio in italiano, chiuso da `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`), `git push -u origin <ramo>`, `gh pr create` con titolo e descrizione in italiano semplice (cosa non andava per l'utente, cosa cambia, test aggiunti), descrizione chiusa da `🤖 Generated with [Claude Code](https://claude.com/claude-code)`.
- MAI `gh pr merge`, MAI auto-merge, MAI --admin. Non toccare file fuori dal tuo argomento.
- Risposta finale: link PR + elenco corretto/non corretto (con motivo) in max 12 righe.
- MAI `git stash` (lo stash è condiviso tra tutti i worktree e altri agenti lo usano): per mettere da parte il lavoro fai un commit temporaneo.
