// Lettura dello schema dietetico e del referto BIA dai PDF (pdf.js).
// Unica copia: la usano la web app (index.html) e l'app iPhone (iOS/Dieta/Risorse/lettore.html,
// tramite un collegamento a questo file). Richiede pdfjsLib già caricato.

// ---------- SCHEMA DIETETICO DAL PDF ----------
// Il PDF viene letto nel browser: il testo è diviso in colonne (nomi a sinistra, grammature a destra)
const GIORNI = ['Lunedì', 'Martedì', 'Mercoledì', 'Giovedì', 'Venerdì', 'Sabato', 'Domenica'];
const PASTI = ['Spuntino', 'Pranzo', 'Cena'];
const PREFISSO = { Contorno: 'Contorno: ', Secondo: 'Secondo: ' };

function parseSchema(righe) {
// righe: [{ sinistra, destra }] in ordine di lettura
const giorni = [];
let giorno = null, pasto = null, opzione = null, sub = '', ignora = false;
for (const r of righe) {
  const L = r.sinistra.trim(), R = r.destra.trim();
  if (!L) continue;
  if (L.startsWith('Avvertenze')) break;
  const g = GIORNI.find((d) => L === d || L.startsWith(d + ' '));
  if (g) {
    giorno = { nome: g, palestra: L.includes('Palestra'), pasti: [] };
    giorni.push(giorno);
    pasto = null; opzione = null; sub = ''; ignora = false;
    continue;
  }
  if (!giorno || ignora) continue;
  if (L.startsWith('Condimento')) { ignora = true; continue; }
  if (PASTI.includes(L) && !R) {
    pasto = { nome: L, opzioni: [] };
    giorno.pasti.push(pasto);
    opzione = { alimenti: [] };
    pasto.opzioni.push(opzione);
    sub = '';
    continue;
  }
  if (L === 'Oppure' && !R) {
    if (!pasto) continue;
    opzione = { alimenti: [] };
    pasto.opzioni.push(opzione);
    sub = '';
    continue;
  }
  if (L === 'Contorno' || L === 'Secondo' || L === 'Frutta') {
    sub = L === 'Frutta' ? '' : L;
    continue;
  }
  if (!pasto || !opzione) continue;
  if (L.startsWith('Olio') || L.startsWith('Acqua')) continue;
  const q = R.replace(/^\((.*)\)$/, '$1');
  // il contorno vale solo per le righe elencate con il trattino
  const pref = sub && L.startsWith('-') ? PREFISSO[sub] || '' : '';
  if (!L.startsWith('-')) sub = '';
  if (L.startsWith('-')) {
    opzione.alimenti.push({ nome: pref + L.slice(1).trim(), quantita: q });
  } else if (R) {
    opzione.alimenti.push({ nome: pref + L, quantita: q });
  } else if (opzione.alimenti.length === 0 && !opzione.titolo) {
    opzione.titolo = L;
  } else {
    opzione.alimenti.push({ nome: pref + L, quantita: '' });
  }
}
return giorni;
}


async function leggiSchemaPdf(file, password = '') {
  const doc = await pdfjsLib.getDocument({ data: await file.arrayBuffer(), password }).promise;
  const righe = [];
  for (let p = 1; p <= doc.numPages; p++) {
    const tc = await (await doc.getPage(p)).getTextContent();
    const rows = {};
    tc.items.forEach((it) => { if (!it.str.trim()) return; const y = Math.round(it.transform[5]); (rows[y] = rows[y] || []).push(it); });
    Object.keys(rows).map(Number).sort((a, b) => b - a).forEach((y) => {
      const items = rows[y].sort((a, b) => a.transform[4] - b.transform[4]);
      let sinistra = '', destra = '', prev = null;
      items.forEach((it) => {
        const x = it.transform[4];
        const parte = x < 240 ? 'sinistra' : 'destra';
        const gap = prev ? x - (prev.x + prev.w) : 0;
        const sep = prev && prev.parte === parte && gap > 1.5 ? ' ' : '';
        if (parte === 'sinistra') sinistra += (sinistra && prev && prev.parte === 'sinistra' ? sep : '') + it.str;
        else destra += (destra && prev && prev.parte === 'destra' ? sep : '') + it.str;
        prev = { x, w: it.width, parte };
      });
      righe.push({ sinistra, destra });
    });
  }
  return parseSchema(righe);
}

// ---------- BIA DAI PDF ----------
// Legge i valori dal referto impedenziometrico (testo estratto riga per riga)
function parseBia(rawText) {
  const text = rawText.split('\n').map((l) => l.replace(/\s*\|\s*/g, ' ').replace(/\s+/g, ' ').trim()).join('\n');
  const num = (x) => parseFloat(String(x).replace(',', '.'));
  const one = (re) => { const m = text.match(re); return m ? num(m[1]) : null; };
  const data = text.match(/VISITA DEL (\d{2})\/(\d{2})\/(\d{4})/);
  return {
    data: data ? `${data[3]}-${data[2]}-${data[1]}` : null,
    peso: one(/\bPeso: ([\d.,]+) kg/),
    grasso_kg: one(/FAT \(Massa Grassa\): ([\d.,]+) kg/),
    grasso_pct: one(/FAT \(Massa Grassa\): [\d.,]+ kg ([\d.,]+)/),
    magra_kg: one(/FFM \(Massa Magra\): ([\d.,]+) kg/),
    magra_pct: one(/FFM \(Massa Magra\): [\d.,]+ kg ([\d.,]+)/),
    acqua_l: one(/TBW \(Acqua Corporea Totale\): ([\d.,]+) lt/),
    bmr: one(/BMR \(Metabolismo Basale\): ([\d.,]+) kcal/),
    vat_cm2: one(/Viscerale \(VAT\): ([\d.,]+) cm/),
    vita_cm: one(/Circonferenza vita: ([\d.,]+) cm/),
    addome_cm: one(/Circonferenza addominale: ([\d.,]+) cm/),
    fianchi_cm: one(/Circonferenza fianchi: ([\d.,]+) cm/),
    torace_cm: one(/Circonferenza torace: ([\d.,]+) cm/),
    obiettivo_peso: one(/Peso Desiderabile: ([\d.,]+) kg/),
    obiettivo_grasso_pct: one(/FAT Desiderabile: ([\d.,]+)\s*%/),
  };
}
async function leggiBiaPdf(file, password = '') {
  const doc = await pdfjsLib.getDocument({ data: await file.arrayBuffer(), password }).promise;
  const out = [];
  for (let p = 1; p <= doc.numPages; p++) {
    const tc = await (await doc.getPage(p)).getTextContent();
    const rows = {};
    tc.items.forEach((it) => { const y = Math.round(it.transform[5]); (rows[y] = rows[y] || []).push({ x: it.transform[4], s: it.str }); });
    Object.keys(rows).map(Number).sort((a, b) => b - a).forEach((y) => out.push(rows[y].sort((a, b) => a.x - b.x).map((i) => i.s).join(' | ')));
  }
  return parseBia(out.join('\n'));
}
