# Recupero dalla Live Activity — piano

1. Test (falliscono): `TimerRecupero` ±15 e salta con notifica rispostata/cancellata (finto); `ancora30`;
   salto del riscaldamento (campo, JSON vecchio, stato Live alla prima serie); categoria notifica.
2. Modello: `Allenamento.riscaldamentoSaltato`; `Palestra.saltaRiscaldamentoDaLive()`; `StatoAllenamentoLive.da`.
3. Timer: `ferma()` tiene l'attesa della notifica; `ancora30()`.
4. Notifiche: categoria e azione, registrazione all'avvio, delegato.
5. Intent e aggancio in `AzioniLive`, impostati in `FormaApp.init`.
6. Widget: pulsanti secondari, layout lock screen e Dynamic Island, anteprime.
7. Stringhe (app e widget), riga «Saltato» nel riscaldamento dell'app.
8. Tutti i FormaTests, commit, PR con base `logica-allenamento`.
