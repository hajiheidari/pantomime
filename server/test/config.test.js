import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { test } from 'node:test';

import { ConfigError, mask, maskedConfig, summary, validateConfig } from '../src/config.js';
import defaultConfig from '../src/default_config.json' with { type: 'json' };

const appDefault = JSON.parse(
  readFileSync(new URL('../../assets/config/default_config.json', import.meta.url), 'utf8'),
);

test('server default config equals the app bundled default', () => {
  assert.deepEqual(defaultConfig, appDefault);
  validateConfig(structuredClone(defaultConfig));
});

test('rejects what the app rejects', () => {
  const bad = (mutate) => {
    const c = structuredClone(defaultConfig);
    mutate(c);
    assert.throws(() => validateConfig(c), ConfigError);
  };
  bad((c) => (c.ads.active_provider.play = 'unity'));
  bad((c) => (c.ads.active_provider.huawei = 'adivery'));
  bad((c) => (c.ads.active_provider.bazaar = 'admob'));
  bad((c) => (c.ads.fallback_chain.myket = ['adivery', 'admob']));
  bad((c) => (c.ads.ab_split = { play: { adivery: 70, tapsell: 20 } }));
  bad((c) => (c.ads.interstitial_every_n_rounds = 11));
  bad((c) => (c.ads.enabled = 'yes'));
  bad((c) => (c.message = 'x'.repeat(501)));
  bad((c) => (c.min_supported_version = 'v2'));
  bad((c) => (c.ads.providers = { adivery: { app_id: 5 } }));
});

test('mask never reveals a full id', () => {
  assert.equal(mask(''), '∅');
  assert.equal(mask('short'), '•••••');
  assert.equal(mask('ca-app-pub-123456789'), 'ca-…789');
  const c = structuredClone(defaultConfig);
  c.ads.providers = {
    adivery: { app_id: 'secret-app-id-123' },
    admob: { ios: { banner: 'ca-app-pub-999/888' } },
  };
  const m = maskedConfig(c);
  assert.equal(m.ads.providers.adivery.app_id, 'sec…123');
  assert.equal(m.ads.providers.admob.ios.banner, 'ca-…888');
  assert.ok(!JSON.stringify(m).includes('secret-app-id-123'));
});

test('summary lists every store', () => {
  const s = summary(defaultConfig);
  for (const store of ['play', 'bazaar', 'myket', 'ios']) assert.match(s, new RegExp(store));
  assert.match(s, /Ads: ON/);
});

test('invalid fixtures are rejected by the bot validator as well', async () => {
  const { readdirSync } = await import('node:fs');
  const dir = new URL('./fixtures/invalid/', import.meta.url);
  const names = readdirSync(dir);
  assert.ok(names.length > 0);
  for (const n of names) {
    const c = JSON.parse(readFileSync(new URL(n, dir), 'utf8'));
    assert.throws(() => validateConfig(c), ConfigError, n);
  }
});
