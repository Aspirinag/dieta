# Temi chiari e scuri + promemoria del mattino

## Perché
L'app deve essere scura quando il telefono è scuro e chiara quando è chiaro, mantenendo i temi Halloween di Slack. I pulsanti principali devono essere "bianchi" (in scuro) invece che verdi; gli accenti restano quelli del tema. In più: un promemoria alle 9 per controllare la dieta del giorno.

## Obiettivi
- Ogni tema ha una versione scura e una chiara; l'app segue il sistema.
- Primario: in scuro pulsanti pieni bianchi con testo scuro; in chiaro pulsanti pieni quasi neri con testo bianco.
- Accento (icone, link, interruttori, calendario): colore del tema, scurito in chiaro per leggersi.
- Promemoria giornaliero alle 9 "Controlla la dieta odierna", con interruttore in Profilo accanto agli altri promemoria.

## Non obiettivi
- Nessun interruttore manuale chiaro/scuro: decide il telefono.
- Nessun cambio ai layout delle schermate.

## Approcci
1. **Palette chiara scelta a mano per tema (scelto).** Più curata, ogni tema resta riconoscibile.
2. Palette chiara calcolata in automatico: più veloce, ma colori a volte spenti.
3. In chiaro solo l'accento su sfondo iOS standard: semplice, ma i temi si somigliano tutti.

## Colori (contrasto accento/secondo ≥ 4,5:1 sullo sfondo, verificato)
| Tema | Scuro: sfondo · accento · secondo | Chiaro: sfondo · accento · secondo |
|---|---|---|
| Slime Time | 0A0A0F→1A1030 · 39FF14 · FF6A00 | F7F5FC→ECE6F7 · 1A7009 · B03A0A |
| Fangtastic | 120C0C→2A1515 · EE5A60 · 8FBF6A | FBF4EC→F2E3D3 · A3101A · 44692A |
| Friendly Ghost | 14173A→2A2F66 · B9A7F0 · 8FE3B0 | F5F3FF→E6E1FA · 5B45B8 · 23704A |
| Candy Corn | 1E1408→3A2810 · F07A2E · FBD98A | FFF3D6→FBD98A · A93F08 · 465F2B |
| Frankenstein | 2A302C→3A433D · 8FBF6A · B7D98A | F1F4EF→E1E8DC · 3F6B2A · 4E6E30 |
| Witching Hour | 0B1330→1F2E5C · 7FD1AE · C9D1E0 | F3F5FB→E2E8F5 · 1B6E53 · 3B4A6B |

Mie scelte (correggibili): l'accento di Fangtastic in scuro passa da B3121B a EE5A60 perché il rosso originale non si legge sul fondo scuro (2,5:1); Candy Corn, che in Slack è solo chiaro, riceve una versione scura inventata (cioccolato + arancio).

## Come
- `Tema` fornisce i colori in base al `colorScheme` dell'ambiente (non più `preferredColorScheme` forzato): questo risolve anche il bug per cui Classico poteva restare scuro.
- Pulsante pieno: `pulsanteVetro(evidente:)` usa tinta primaria (bianco/quasi nero) e testo opposto.
- Righe lista: vetro bianco 8% in scuro, bianco 55% in chiaro (come oggi).
- Promemoria: `Promemoria.mattino` (predefinito attivo), `Notifiche.giornaliera(id: "mattino", ora: 9)` in `programmaPromemoria()`.

## Verifica
Build in CI e schermate del simulatore in chiaro e scuro (il flusso già produce `light-*` e `dark-*`), controllate prima di dire che è pronto.
