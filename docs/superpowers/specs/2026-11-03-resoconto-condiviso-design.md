# Resoconto da condividere con nutrizionista e trainer

Data: 3 novembre 2026 · Stato: bozza da approvare

## Perché

L'utente segue la dieta di un nutrizionista e si allena con un personal trainer. Oggi i piani arrivano in PDF su WhatsApp e i progressi non tornano indietro in modo ordinato: foto, messaggi sparsi, conversazioni da risalire.

L'obiettivo a lungo termine è vendere Forma come posto unico in cui nutrizionista e trainer seguono lo stesso cliente. Nessun concorrente trovato lo fa: vedi `reports/Mercato app nutrizionisti e trainer.md` nella cartella home dell'utente. La versione con server e account costa però troppo per il budget attuale: 5 ore a settimana e al massimo 1.000 €.

Questo primo passo serve a **verificare se i professionisti trovano utile ricevere i dati del cliente da Forma**, senza server e senza obblighi sui dati altrui. Lo si prova prima con il nutrizionista e il trainer dell'utente, poi con una decina di altri professionisti.

## Obiettivi

- Dall'app, il cliente crea un **PDF di una pagina** per il nutrizionista e uno, separato, per il trainer. Li manda con il menu Condividi di iPhone (WhatsApp, Mail, AirDrop, stampa).
- Ognuno riceve **solo la sua parte**: il nutrizionista dieta e peso, il trainer gli allenamenti.
- In cima al PDF ci sono i **numeri grandi**, leggibili già nell'anteprima della chat. Sotto c'è il **dettaglio giorno per giorno**.

## Fuori da questo passo (non-obiettivi)

- Server, account, sincronizzazione, risposte o modifiche del professionista dentro l'app.
- Peso corporeo nella parte del trainer: l'utente ha deciso che il trainer vede solo gli allenamenti.
- Pubblicazione su App Store, prezzi, abbonamenti: si decidono dopo la prova con i professionisti.

## Cosa sarebbe un fallimento (anti-obiettivi)

- Il resoconto manda al trainer dati della dieta, o al nutrizionista dati della palestra.
- Il PDF contiene dati che il cliente non ha visto prima di mandarlo.
- Per leggere il resoconto il professionista deve installare qualcosa o creare un account.
- Il resoconto inventa dati: un giorno senza registrazioni deve risultare vuoto, non «0 su 5».

## Come funziona

### Dove si crea
- **Dieta → Andamento:** pulsante «Manda al nutrizionista».
- **Palestra → Storico:** pulsante «Manda al trainer».
- Il tocco apre un foglio di anteprima con:
  - il periodo, modificabile;
  - una **nota libera facoltativa** (es. «mercoledì cena fuori per lavoro»), stampata nel PDF;
  - l'anteprima del PDF e il pulsante Condividi.

### Periodo
- Di base va **dall'ultimo invio a quel professionista fino a oggi**. La data dell'ultimo invio è salvata separatamente per nutrizionista e trainer.
- La prima volta, o se l'ultimo invio è più vecchio di 31 giorni: **gli ultimi 7 giorni**.
- L'utente può cambiare le date prima di mandare. La data di «ultimo invio» si aggiorna solo quando il foglio Condividi si chiude con un invio riuscito.

### Resoconto per il nutrizionista
- **Intestazione:** «Resoconto dieta — <nome del profilo>», periodo, nome del piano attivo.
- **Numeri grandi:**
  - pasti seguiti in %, sui soli giorni con un piano;
  - peso più recente e variazione rispetto alla prima pesata del periodo;
  - acqua media al giorno.
- **Tabella giorno per giorno:**
  - pasti segnati su previsti;
  - nomi dei pasti non segnati;
  - acqua e olio.
  - I giorni senza piano o senza registrazioni compaiono come «—».
- **Pesate del periodo:** tutte le misure con il solo peso, in ordine di data.
- **Ultima BIA:**
  - è l'ultima misura con composizione corporea (grasso, massa magra o circonferenze), **anche se precedente al periodo**;
  - riporta la data e il confronto con la BIA prima di quella.
  - Le BIA di solito sono mensili o dopo 3 pesate, quindi non vanno filtrate sul periodo.
- **Nota del cliente**, se c'è.
- **Piè di pagina:** «Creato con Forma · i dati restano sul telefono di <nome>».

### Resoconto per il trainer
- **Intestazione:** «Resoconto allenamenti — <nome>», periodo.
- **Numeri grandi:**
  - allenamenti fatti su previsti;
  - volume totale e variazione rispetto al periodo precedente della stessa lunghezza;
  - numero di sessioni cardio.
  - I previsti sono i giorni pesi e cardio del piano settimanale, con le settimane A/B se attive.
- **Tabella giorno per giorno:**
  - scheda e durata;
  - le 2-3 serie migliori, con ★ per i record personali;
  - i giorni previsti e non fatti in rosso con «saltato», compresi quelli segnati «non sono andato»;
  - il cardio dal Watch con minuti, km e battito medio.
- **Progressi per esercizio:** per ogni esercizio fatto nel periodo, la serie migliore di adesso a confronto con l'ultima volta prima del periodo, con ↑ = ↓.
- **Nota del cliente**, se c'è. Piè di pagina come sopra.

### Aspetto
- Una pagina A4 verticale, leggibile anche sul telefono.
- Colori sobri: verde salvia per i numeri grandi, rosso solo per i giorni saltati. Testo nero su bianco.
- Se il contenuto supera una pagina, la tabella continua su una seconda pagina. I numeri grandi stanno sempre in cima alla prima.
- Le bozze approvate sono in `.superpowers/brainstorm/` (`resoconto-proposta.html`).

## Vincoli

- Nessun server, nessun dato in uscita se non il PDF che l'utente sceglie di mandare.
- Il formato di `dieta.json` resta compatibile con la web app. Le date di ultimo invio stanno fuori dal JSON della dieta (preferenze dell'app) o in campi nuovi con valore predefinito.
- Si usano solo dati che Forma ha già:
  - dieta: `Profilo.dieta`, `Registro.slot`, `olio`, `acqua`, `Profilo.piani`, `Profilo.bia`;
  - palestra: `StatoPalestra.allenamenti`, `cardio`, `piani`, `saltati`, `usaAB`, e i record di `nuoviRecord`.
- Testi in italiano semplice. Accessibile con testo grande e VoiceOver nel foglio di anteprima.

## Regole di calcolo (scelte mie, dopo la revisione)

- **Giorno registrato (dieta):** un giorno con almeno un pasto segnato, acqua o olio. Gli altri compaiono come «—» e non entrano nella % né nella media dell'acqua.
- **Oggi:** entra solo se ha già registrazioni (dieta) o un allenamento fatto (palestra). Un oggi vuoto non conta mai come saltato.
- **Pasti:** la % è pasti segnati / pasti del piano, sui soli giorni registrati con un piano. Nella tabella vanno solo i nomi dei pasti non segnati, senza opzioni e alimenti.
- **Allenamenti previsti:** i giorni pesi e cardio del piano (A/B se attive), solo dal primo allenamento registrato in poi. Un giorno previsto conta come fatto se c'è almeno un allenamento o una sessione cardio (anche solo Watch o da Salute). Più allenamenti nello stesso giorno contano una volta. Gli allenamenti in giorni di riposo compaiono in tabella come «extra» e non cambiano «fatti su previsti».
- **Niente confronto possibile:** se manca il periodo precedente, la volta precedente di un esercizio o una seconda pesata, al posto della variazione si scrive «prima volta». Mai uno 0 inventato.
- **Pesate e BIA:** una pesata è una misura con il peso. Una BIA è una misura con grasso o massa magra; le sole circonferenze non bastano. Una BIA con il peso vale anche come pesata. Si mostrano solo i campi presenti.
- **Pagine:** la pagina 1 ha intestazione, numeri grandi e l'inizio della tabella. La tabella continua sulle pagine dopo, e pesate e BIA (o progressi) vengono subito dopo la tabella. Si usa `UIGraphicsPDFRenderer`, che va a capo bene su più pagine.
- **Invio riuscito:** la data di ultimo invio si aggiorna quando il foglio Condividi risponde «completato». Se l'app di destinazione sbaglia, il danno è piccolo, perché il periodo si può sempre cambiare a mano.
- **Di chi è la palestra (deciso dall'utente):** la palestra la usa solo il proprietario del telefono. Il resoconto del trainer porta il nome del primo profilo, qualunque sia il profilo attivo. L'ultimo invio al trainer è uno solo per l'app, quello al nutrizionista è separato per ogni profilo.
- **Ultimo invio:** salvato in `UserDefaults`, quindi fuori da `dieta.json`. Non torna con un backup, e va bene così: al massimo si riparte dagli ultimi 7 giorni.
- **Cosa finisce nel PDF:** solo i campi elencati sopra più la nota scritta nel foglio di anteprima. Le note del profilo non ci finiscono mai. L'anteprima mostra il PDF vero, e niente interruttori per togliere sezioni in questa prima versione.

## Lasciato a chi costruisce

- Come si genera il PDF (`ImageRenderer` di SwiftUI o `UIGraphicsPDFRenderer`).
- La disposizione esatta delle colonne e la scelta delle «serie migliori» (per esempio il massimale stimato più alto per esercizio).
- Il nome del file, per esempio `Resoconto dieta Marco 27 ott - 2 nov.pdf`.

## Dopo

Se almeno 5-10 professionisti dicono che pagherebbero per vedere i clienti così, si progetta la versione con server: account, condivisione diretta, regole GDPR, hosting in UE. Il rapporto di ricerca elenca i passi.
