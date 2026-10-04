#!/usr/bin/env node
// Copies the live word list (edited with the bot) into the app's bundled
// assets/words/words_fa.json, so a new release ships with the latest words.
// Run before every release:
//
//   cd server && node scripts/pull-words.mjs [https://<worker>/words_fa.json]
//
// Behind a proxy: NODE_USE_ENV_PROXY=1 node scripts/pull-words.mjs
import { readFileSync, writeFileSync } from 'node:fs';
import { validatePack } from '../src/words.js';

const url = process.argv[2] ?? 'https://pantomime-config.sepanta-hesaban.workers.dev/words_fa.json';
const target = new URL('../../assets/words/words_fa.json', import.meta.url);
const res = await fetch(url, { cache: 'no-store' });
if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`);
const pack = await res.json();
validatePack(pack);
const local = JSON.parse(readFileSync(target, 'utf8'));
if (pack.version <= local.version) {
  console.log(`bundled words are already v${local.version} (live: v${pack.version}); nothing to do`);
} else {
  writeFileSync(target, `${JSON.stringify(pack, null, 2)}\n`);
  console.log(`assets/words/words_fa.json: v${local.version} → v${pack.version}`);
}
