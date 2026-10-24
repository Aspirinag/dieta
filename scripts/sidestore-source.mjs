// Crea la sorgente per SideStore (formato AltStore) che punta all'ultima .ipa pubblicata
// Uso: node scripts/sidestore-source.mjs <versione> <file.ipa> <url di download>
import { statSync, writeFileSync } from 'node:fs';

const [version, ipa, downloadURL] = process.argv.slice(2);
const source = {
  name: 'Dieta',
  identifier: 'io.github.aspirinag.dieta.source',
  apps: [{
    name: 'Dieta',
    bundleIdentifier: 'io.github.aspirinag.dieta',
    developerName: 'aspirinag',
    localizedDescription: 'Piano alimentare del giorno, schema dietetico e BIA da PDF, andamento del peso.',
    iconURL: 'https://raw.githubusercontent.com/aspirinag/dieta/main/ios/App/App/Assets.xcassets/AppIcon.appiconset/AppIcon-512@2x.png',
    versions: [{
      version,
      date: new Date().toISOString(),
      downloadURL,
      size: statSync(ipa).size,
      minOSVersion: '15.0',
    }],
  }],
  news: [],
};
writeFileSync('sidestore.json', JSON.stringify(source, null, 2));
console.log('sidestore.json pronta');
