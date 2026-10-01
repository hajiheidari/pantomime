// Writes configs produced by real bot commands to test/fixtures/, which the
// app's Dart tests parse (test/ads/server_fixtures_test.dart). Keeps the bot
// validator and the app validator in agreement.
import { mkdirSync, rmSync, writeFileSync } from 'node:fs';

import { runCommand } from '../src/commands.js';
import defaultConfig from '../src/default_config.json' with { type: 'json' };

const dir = new URL('../test/fixtures/', import.meta.url);
rmSync(dir, { recursive: true, force: true });
mkdirSync(new URL('valid/', dir), { recursive: true });
mkdirSync(new URL('invalid/', dir), { recursive: true });

const scenarios = {
  'default': [],
  'split-and-fallback': ['/split bazaar adivery:50,tapsell:50', '/fallback play adivery,admob', '/every 2'],
  'ads-off-notice': ['/ads off', '/notice بازی به‌روز شد 🎉', '/minversion 1.2.3'],
  'all-keys': [
    '/keys adivery app_id adv-app',
    '/keys adivery interstitial_placement adv-int',
    '/keys tapsell app_key tp-key',
    '/keys admob_android banner ca-app-pub-1/2',
    '/keys admob_ios rewarded ca-app-pub-3/4',
    '/rewarded off',
    '/banner off',
    '/provider ios admob',
  ],
};

for (const [name, commands] of Object.entries(scenarios)) {
  let config = structuredClone(defaultConfig);
  let version = 0;
  for (const cmd of commands) {
    const r = runCommand(cmd, config);
    if (!r.config) throw new Error(`${name}: "${cmd}" failed: ${r.reply}`);
    config = r.config;
    config.config_version = ++version;
  }
  writeFileSync(new URL(`valid/${name}.json`, dir), `${JSON.stringify(config, null, 2)}\n`);
}

const invalid = {
  'admob-on-bazaar': (c) => (c.ads.active_provider.bazaar = 'admob'),
  'unknown-provider': (c) => (c.ads.fallback_chain.play = ['adivery', 'unityads']),
  'split-sum': (c) => (c.ads.ab_split = { myket: { adivery: 10, tapsell: 10 } }),
  'every-zero': (c) => (c.ads.interstitial_every_n_rounds = 0),
};
for (const [name, mutate] of Object.entries(invalid)) {
  const c = structuredClone(defaultConfig);
  mutate(c);
  writeFileSync(new URL(`invalid/${name}.json`, dir), `${JSON.stringify(c, null, 2)}\n`);
}
console.log('fixtures written');
