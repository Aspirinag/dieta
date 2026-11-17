# Audit giro Forma (simulatore iPhone 17, iOS 27, build Debug, dati -demo)

Limiti del giro: gli strumenti di tocco lavorano sull albero di accessibilita; in allenamento le spunte delle serie non sono raggiungibili (vedi problema 1), quindi NON ho potuto provare: spuntare serie, timer di recupero, finire e salvare l allenamento, calendario/progressi toccati, promemoria, backup. Non provati: testo grande oltre un test visivo, scuro solo su Oggi/Dieta/Progressi in inglese.

Nessun crash incontrato.

## Problemi

1. ALTA (accessibilita) - Allenamento in corso, riga serie. Il cerchio di spunta di ogni serie NON compare come pulsante nell albero di accessibilita (ci sono solo "Usa i valori dell ultima volta", +/-2,5 kg, campi kg/rip). Con VoiceOver / automazione non si puo segnare una serie fatta. Riprodurre: -demo -tab inCorso, snapshot UI. File probabile: vista riga serie in iOS/Forma/... (cercare "Usa i valori dell'ultima volta").
2. ALTA (accessibilita) - Allenamento, "Fine": la conferma "Finire l allenamento? 5 serie senza spunta non verranno salvate" e un popover con solo "Finisci e salva": il pulsante non e esposto nell albero di accessibilita e non c e un "Annulla" visibile (si chiude toccando fuori). Riprodurre: inCorso -> Fine.
3. MEDIA - Allenamento a tutto schermo: la schermata Oggi dietro (pasti "Segna ...", Olio, Acqua, Peso, "Riprendi") resta esposta all accessibilita sotto la scheda; si possono toccare per errore con VoiceOver e confonde. Riprodurre: inCorso, snapshot UI.
4. MEDIA - Oggi, riquadri Olio e Acqua: 6 + 8 pulsanti (meno/piu) senza etichetta ("e98..e103" nello snapshot). VoiceOver legge solo "pulsante". Funzionano (olio 2 -> 1 cucchiaino). Riprodurre: -tab oggi, snapshot UI. Aggiungere accessibilityLabel "Togli un cucchiaino"/"Aggiungi un bicchiere" ecc.
5. BASSA (accessibilita) - Modifica piano: interruttore "Giorno di palestra" senza etichetta propria (la scritta e un testo separato); anche altri campi: i campi quantita (es. "150 g") non dicono a quale alimento appartengono nell albero.
6. BASSA - Modifica piano, campo quantita: scrivere "200 g" in un campo che contiene "150 g" senza prima selezionarlo produce "200 g150 g" (il testo non viene selezionato al tocco). Per chi tocca il campo e digita e scomodo: selezionare tutto al focus. File: vista di modifica piano (Impostazioni > Piani alimentari > piano). Nota: potrebbe dipendere dallo strumento di test, da riverificare a mano.
7. BASSA - Lista spesa: spuntando un alimento, la riga scende in fondo alla lista e le altre salgono sotto il dito (es. spuntato "Insalata" salta dopo "Zucchine"); si rischia di toccare la riga sbagliata al tap successivo. Riprodurre: Dieta > Spesa > tocca "Segna Insalata", poi la riga successiva.
8. BASSA - Inglese (-AppleLanguages "(en)"): restano in italiano i nomi dei pasti Colazione/Pranzo/Spuntino/Cena e "Piano di esempio" (sono dati del piano demo, forse voluti); "Option: Riso (2 of 2)" mischia le lingue. Titoli, giorni, tab, Progress sono tradotti bene.
9. BASSA - Avvio freddo: con -tab progressi la prima schermata era completamente bianca a 2 s dall avvio (a 5 s era a posto). Possibile lampo bianco all avvio in tema chiaro/scuro: da verificare su dispositivo.
10. BASSA - Il rientro sul tab chiesto con -tab progressi/impostazioni durante un allenamento in corso apre direttamente la scheda "Scheda pesi" a tutto schermo (ripresa), non il tab: voluto, ma confonde chi prova i percorsi. Inoltre dopo il riavvio la serie 1 di Chest press (spuntata a 40x10 prima) era di nuovo vuota e le serie passate da 3 a 2 (2.800 kg/4 serie -> 2.400 kg/3 serie): lo stato dell allenamento dei dati demo non resta stabile tra riavvii, o la ripresa perde la spunta. Da verificare a mano su dati veri.

## Cose che funzionano
- Segna pasto (Oggi e Dieta si aggiornano insieme; Pranzo 3 -> 2 di 4 coerente nel selettore giorni).
- Peso: apre pannello, +/-0,1 kg, Salva aggiorna "81,3 kg, oggi, -1,2 kg in 30 giorni".
- Cambio giorno in Dieta, dettaglio pasto, Spesa (spunte, contatori "1 di 11 presi", "Togli le spunte").
- Impostazioni > Piani alimentari > apre e salva l editor del piano senza errori.
- Tema scuro e inglese: nessun testo tagliato su Oggi, Dieta, Progress; tab bar flottante copre l ultima riga (normale, ma serve spazio in fondo).
- Palestra: schede, "Questa settimana: 1 allenamento · 30 min", Altro > Registra cardio visibili.
