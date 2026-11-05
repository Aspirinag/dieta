// Controlla che la web app (index.html) ritrovi i dati già salvati e conservi
// tutti i campi di un backup di Forma, anche quelli che non usa.
// Esegue in Node le funzioni di caricamento e salvataggio prese da index.html.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import assert from 'node:assert/strict';

const radice = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(radice, 'index.html'), 'utf8');

function tratto(da, a) {
  const i = html.indexOf(da), j = html.indexOf(a, i);
  if (i < 0 || j < 0) throw new Error(`index.html: non trovo il tratto da «${da}» a «${a}»`);
  return html.slice(i, j);
}

// Funzioni dei dati: costanti, load/save e funzioni di aiuto (piano del giorno, spunte)
const codice = [
  tratto('const OLIO_DEF', 'let state = load()'),
  tratto('function load()', '// ---------- APP PER IPHONE'),
  tratto('const prof = ()', '// ---------- SCHEMA DIETETICO'),
  tratto('function addPiano(p)', '\n  }\n') + '\n  }\n',
  tratto('function azzeraSpesa()', '\n  }\n') + '\n  }\n',
].join('\n');

function apri(salvato) {
  const memoria = new Map(salvato == null ? [] : [['dieta:v1', salvato]]);
  const localStorage = {
    getItem: (k) => (memoria.has(k) ? memoria.get(k) : null),
    setItem: (k, v) => memoria.set(k, String(v)),
  };
  const f = new Function('localStorage', 'NATIVO', 'Plugin', `
    ${codice}
    let state = load();
    return { get state() { return state; }, set state(s) { state = s; }, load, save, planFor, slotState, addPiano, azzeraSpesa, DEFAULT };
  `);
  return { app: f(localStorage, false, () => ({})), memoria };
}

const piano = {
  nome: 'Schema Dietetico', dal: '2026-11-02', al: '',
  giorni: [{ nome: 'Lunedì', palestra: false, pasti: [
    { nome: 'Pranzo', opzioni: [{ alimenti: [{ nome: 'Pasta integrale', quantita: '80g' }] }, { titolo: 'Oppure', alimenti: [{ nome: 'Riso', quantita: '70g' }] }] },
  ] }],
};

let prove = 0;
function prova(nome, fn) { fn(); prove++; console.log(`ok  ${nome}`); }

prova('salvataggio della vecchia web app ritrovato uguale', () => {
  const vecchio = {
    profili: {
      raffaele: { nome: 'Raffaele', piani: [], bia: [], dieta: {} },
      alessandra: { nome: 'Alessandra', piani: [piano], bia: [{ data: '2026-10-01', peso: 60 }],
        dieta: { '2026-11-02': { slot: { 0: { opt: 1, fatto: true } }, olio: 3, acqua: 1.5 } }, olio_tot: 5 },
    },
    attivo: 'alessandra',
  };
  const { app, memoria } = apri(JSON.stringify(vecchio));
  assert.deepEqual(app.state, vecchio);
  assert.equal(app.planFor('2026-11-02').nome, 'Schema Dietetico');
  assert.deepEqual(app.slotState('2026-11-02', 0), { opt: 1, fatto: true });
  app.save();
  assert.deepEqual(JSON.parse(memoria.get('dieta:v1')), JSON.parse(JSON.stringify(app.state)));
});

prova('backup di Forma: nessun campo perso dopo un salvataggio', () => {
  const forma = {
    attivo: 'io',
    promemoria: { acqua: false, acquaAlle: 1200, acquaDalle: 600, acquaOgni: 2, mattino: true, oraMattino: 540, oraPasti: 1260, pasti: false },
    profili: { io: { nome: 'Io', note: '', piani: [piano], bia: [], dieta: {},
      spesa: { settimana: '2026-11-02', presi: { 'Riso': true }, extra: ['Detersivo'] },
      spesa_prossima: { settimana: '2026-11-09', presi: {} } } },
  };
  // come l'import del backup in index.html: { ...DEFAULT, ...backup }
  const { app, memoria } = apri(null);
  app.state = { ...structuredClone(app.DEFAULT), ...forma };
  app.save();
  const riletto = apri(memoria.get('dieta:v1')).app.state;
  assert.deepEqual(riletto.promemoria, forma.promemoria);
  assert.deepEqual(riletto.profili.io, forma.profili.io);
  assert.equal(riletto.attivo, 'io');
});

prova('nessun dato salvato: si parte dai profili predefiniti', () => {
  const { app } = apri(null);
  assert.ok(Object.keys(app.state.profili).length > 0);
  assert.ok(app.state.profili[app.state.attivo]);
});

prova('nuovo piano dal PDF: si salva e chiude il piano precedente', () => {
  const { app } = apri(JSON.stringify({ profili: { a: { nome: 'A', piani: [piano], bia: [], dieta: {} } }, attivo: 'a' }));
  app.addPiano({ ...piano, nome: 'Nuovo', dal: '2026-12-01' });
  const piani = app.state.profili.a.piani;
  assert.equal(piani.length, 2);
  assert.equal(piani[0].al, '2026-11-30');
  assert.equal(app.planFor('2026-12-05').nome, 'Nuovo');
  assert.equal(app.planFor('2026-11-10').nome, 'Schema Dietetico');
});

prova('«Togli le spunte» tiene le voci aggiunte a mano in Forma', () => {
  const { app } = apri(JSON.stringify({ profili: { a: { nome: 'A', piani: [], bia: [], dieta: {},
    spesa: { settimana: '2026-11-02', presi: { Riso: true }, extra: ['Detersivo'] } } }, attivo: 'a' }));
  app.azzeraSpesa();
  assert.deepEqual(app.state.profili.a.spesa.presi, {});
  assert.deepEqual(app.state.profili.a.spesa.extra, ['Detersivo']);
});

console.log(`${prove} prove passate`);
