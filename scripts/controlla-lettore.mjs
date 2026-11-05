// Controlla che il codice di lettura dei PDF sia uguale nella web app (index.html)
// e nell'app per iPhone (iOS/Forma/Risorse/lettore.html).
// Confronta il blocco tra i due marcatori, riga per riga, senza badare agli spazi
// a inizio e fine riga e alle righe vuote. Esce con 1 alla prima differenza.
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const radice = join(dirname(fileURLToPath(import.meta.url)), '..');
const INIZIO = '// --- lettore: inizio ---';
const FINE = '// --- lettore: fine ---';

function blocco(percorso) {
  const testo = readFileSync(join(radice, percorso), 'utf8');
  const a = testo.indexOf(INIZIO), b = testo.indexOf(FINE);
  if (a < 0 || b < a) { console.error(`${percorso}: marcatori del lettore mancanti`); process.exit(1); }
  return testo.slice(a + INIZIO.length, b).split('\n').map((r) => r.trim()).filter(Boolean);
}

const web = blocco('index.html');
const app = blocco('iOS/Forma/Risorse/lettore.html');
for (let i = 0; i < Math.max(web.length, app.length); i++) {
  if (web[i] !== app[i]) {
    console.error(`Il lettore dei PDF è diverso (riga ${i + 1} del blocco):`);
    console.error(`  index.html:   ${web[i] ?? '(fine)'}`);
    console.error(`  lettore.html: ${app[i] ?? '(fine)'}`);
    process.exit(1);
  }
}
console.log(`Lettore dei PDF uguale nei due file (${web.length} righe).`);
