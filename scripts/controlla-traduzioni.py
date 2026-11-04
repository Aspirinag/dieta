#!/usr/bin/env python3
"""Controlla il catalogo delle stringhe: ogni voce deve avere en e en-GB, non vuoti e non «da rivedere»;
en-GB deve essere uguale a en, salvo le voci in DIVERSE_IN_GB.

Uso: python3 scripts/controlla-traduzioni.py [catalogo ...]
Senza argomenti controlla iOS/Forma/Localizable.xcstrings e iOS/Forma/InfoPlist.xcstrings.
Esce con 1 se trova problemi. Le voci con "shouldTranslate": false (numeri, simboli) si saltano.
"""
import json
import pathlib
import sys

RADICE = pathlib.Path(__file__).resolve().parent.parent
PREDEFINITI = [RADICE / "iOS/Forma/Localizable.xcstrings", RADICE / "iOS/Forma/InfoPlist.xcstrings"]
STATI_NON_FINITI = {"new", "needs_review", "stale"}
# Voci in cui l'inglese britannico è davvero diverso da quello americano (le altre devono essere uguali)
DIVERSE_IN_GB = {"Salto della corda", "Pallino pieno: pesi o cardio fatti. Grigio: in programma. ✕: saltato."}


def valori(loc):
    """Tutte le stringhe di una localizzazione (semplice o con varianti)."""
    if "stringUnit" in loc:
        yield loc["stringUnit"]
    for gruppo in loc.get("variations", {}).values():
        for variante in gruppo.values():
            yield from valori(variante)
    for sub in loc.get("substitutions", {}).values():
        for variante in sub.get("variations", {}).get("plural", {}).values():
            yield from valori(variante)


def controlla(percorso):
    cat = json.loads(percorso.read_text())
    problemi, totale, saltate, gb = [], 0, 0, 0
    for chiave, voce in cat["strings"].items():
        if voce.get("shouldTranslate") is False:
            saltate += 1
            continue
        totale += 1
        loc = voce.get("localizations", {})
        for lingua in ("en", "en-GB"):
            if lingua not in loc:
                problemi.append(f"{chiave!r}: manca {'l’inglese' if lingua == 'en' else 'en-GB'}")
                continue
            unita = list(valori(loc[lingua]))
            if not unita:
                problemi.append(f"{chiave!r}: {lingua} senza testo")
            for u in unita:
                if not u.get("value", "").strip():
                    problemi.append(f"{chiave!r}: {lingua} vuoto")
                if u.get("state") in STATI_NON_FINITI:
                    problemi.append(f"{chiave!r}: {lingua} in stato {u['state']}")
        if "en-GB" in loc:
            gb += 1
            if "en" in loc and loc["en"] != loc["en-GB"] and chiave not in DIVERSE_IN_GB:
                problemi.append(f"{chiave!r}: en-GB diverso da en (se voluto, aggiungila a DIVERSE_IN_GB)")
    print(f"{percorso.name}: {totale} voci da tradurre, {saltate} senza traduzione (numeri e simboli), {gb} con variante britannica")
    return problemi


def main():
    percorsi = [pathlib.Path(p) for p in sys.argv[1:]] or PREDEFINITI
    problemi = []
    for p in percorsi:
        problemi += controlla(p)
    for p in problemi:
        print("PROBLEMA:", p)
    print("OK: nessuna voce inglese mancante o vuota" if not problemi else f"{len(problemi)} problemi")
    return 1 if problemi else 0


if __name__ == "__main__":
    sys.exit(main())
