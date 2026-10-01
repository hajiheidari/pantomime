import assert from 'node:assert/strict';
import { test } from 'node:test';

import { runCommand } from '../src/commands.js';
import defaultConfig from '../src/default_config.json' with { type: 'json' };

const cfg = () => structuredClone(defaultConfig);

test('/provider changes the active network, validates store rules', () => {
  const r = runCommand('/provider bazaar tapsell', cfg());
  assert.equal(r.config.ads.active_provider.bazaar, 'tapsell');
  assert.match(runCommand('/provider bazaar admob', cfg()).reply, /not allowed/);
  assert.match(runCommand('/provider huawei adivery', cfg()).reply, /usage/);
  assert.match(runCommand('/provider play unity', cfg()).reply, /usage/);
  assert.equal(runCommand('/provider@PantomimeBot ios admob', cfg()).config.ads.active_provider.ios, 'admob');
});

test('/split sets and removes an A/B test', () => {
  const on = runCommand('/split myket adivery:30,tapsell:70', cfg());
  assert.deepEqual(on.config.ads.ab_split.myket, { adivery: 30, tapsell: 70 });
  const off = runCommand('/split myket off', on.config);
  assert.equal(off.config.ads.ab_split.myket, undefined);
  assert.match(runCommand('/split play adivery:60,tapsell:60', cfg()).reply, /sum to 100/);
  assert.match(runCommand('/split bazaar adivery:50,admob:50', cfg()).reply, /not allowed/);
  assert.match(runCommand('/split ios admob:100', cfg()).reply, /usage/);
  assert.match(runCommand('/split play adivery=50', cfg()).reply, /bad split/);
});

test('/fallback', () => {
  assert.deepEqual(runCommand('/fallback play tapsell,adivery', cfg()).config.ads.fallback_chain.play, [
    'tapsell',
    'adivery',
  ]);
  assert.match(runCommand('/fallback bazaar adivery,admob', cfg()).reply, /not allowed/);
  assert.match(runCommand('/fallback play adivery,adivery', cfg()).reply, /duplicate/);
});

test('on/off switches and /every', () => {
  assert.equal(runCommand('/ads off', cfg()).config.ads.enabled, false);
  assert.equal(runCommand('/rewarded off', cfg()).config.ads.rewarded_enabled, false);
  assert.equal(runCommand('/banner off', cfg()).config.ads.banner_on_home, false);
  assert.match(runCommand('/ads maybe', cfg()).reply, /usage/);
  assert.equal(runCommand('/every 5', cfg()).config.ads.interstitial_every_n_rounds, 5);
  for (const bad of ['/every 0', '/every 11', '/every x', '/every 2.5']) {
    assert.match(runCommand(bad, cfg()).reply, /usage/, bad);
  }
});

test('/notice and /minversion', () => {
  const r = runCommand('/notice   نسخه جدید آمد!  ', cfg());
  assert.equal(r.config.message, 'نسخه جدید آمد!');
  assert.equal(runCommand('/notice off', r.config).config.message, null);
  assert.match(runCommand(`/notice ${'x'.repeat(501)}`, cfg()).reply, /500/);
  assert.equal(runCommand('/minversion 1.4.0', cfg()).config.min_supported_version, '1.4.0');
  assert.match(runCommand('/minversion latest', cfg()).reply, /usage/);
});

test('/keys guided flow never echoes the secret', () => {
  let r = runCommand('/keys', cfg(), null);
  assert.deepEqual(r.session, { step: 'target' });
  r = runCommand('facebook', cfg(), r.session);
  assert.equal(r.session.step, 'target');
  r = runCommand('admob_ios', cfg(), r.session);
  assert.equal(r.session.step, 'field');
  r = runCommand('rewarded', cfg(), r.session);
  assert.equal(r.session.step, 'value');
  const secret = 'ca-app-pub-1234567890/0987654321';
  r = runCommand(secret, cfg(), r.session);
  assert.equal(r.config.ads.providers.admob.ios.rewarded, secret);
  assert.equal(r.session, null);
  assert.equal(r.deleteMessage, true);
  assert.ok(!r.reply.includes(secret));
});

test('/keys one-shot form and /cancel', () => {
  const r = runCommand('/keys adivery app_id my-adivery-app-id', cfg());
  assert.equal(r.config.ads.providers.adivery.app_id, 'my-adivery-app-id');
  assert.ok(!r.reply.includes('my-adivery-app-id'));
  assert.equal(r.deleteMessage, true);
  assert.match(runCommand('/keys adivery zone x', cfg()).reply, /unknown/);
  assert.equal(runCommand('/cancel', cfg(), { step: 'value' }).session, null);
  const cleared = runCommand('-', r.config, { step: 'value', target: 'adivery', field: 'app_id' });
  assert.equal(cleared.config.ads.providers.adivery.app_id, '');
});

test('/status, /show, /help, unknown', () => {
  assert.match(runCommand('/status', cfg()).reply, /config v0/);
  const c = runCommand('/keys tapsell app_key super-secret-key-42', cfg()).config;
  const shown = runCommand('/show', c).reply;
  assert.ok(!shown.includes('super-secret-key-42'));
  assert.match(shown, /sup…-42/);
  assert.match(runCommand('/help', cfg()).reply, /\/provider/);
  assert.match(runCommand('/nope', cfg()).reply, /Unknown command/);
  assert.equal(runCommand('/rollback', cfg()).rollback, true);
  // Plain text without a /keys session → help.
  assert.match(runCommand('hello', cfg()).reply, /\/status/);
});
